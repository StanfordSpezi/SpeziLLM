//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Atomics
import Foundation
import GeneratedOpenAIClient
import OpenAPIRuntime
import OpenAPIURLSession
import os
import SpeziChat
import SpeziFoundation
import SpeziKeychainStorage
import SpeziLLM

/// Represents an ``LLMOpenAIRealtimeSchema`` in execution.
///
/// The ``LLMOpenAIRealtimeSession`` is the executable version of the OpenAI Realtime LLM containing context and state as defined by the ``LLMOpenAIRealtimeSchema``.
/// It provides access to realtime models from OpenAI, such as gpt-realtime  or GPT-4o Realtime.
/// Also provides a way to transcribe those conversations using models such as GPT-4o Transcribe or Whisper.
///
/// A text inference is started by ``LLMOpenAIRealtimeSession/generate()``, returning an `AsyncThrowingStream` and can be cancelled via ``LLMOpenAIRealtimeSession/cancel()``.
/// The ``LLMOpenAIRealtimeSession`` exposes the user and assistant's audio transcripts via the ``LLMOpenAIRealtimeSession/context`` property, containing all the transcript history with the Realtime API.
///
/// - Warning: The ``LLMOpenAIRealtimeSession`` shouldn't be created manually but always through the ``LLMOpenAIRealtimePlatform`` via the `LLMRunner`.
///
/// - Tip: ``LLMOpenAIRealtimeSession`` also enables the function calling mechanism to establish a structured, bidirectional, and reliable communication
///   between the OpenAI LLMs and external tools. For details, refer to `LLMFunction` and `LLMFunction/Parameter` from SpeziLLMOpenAI, or see SpeziLLMOpenAI's FunctionCalling documentation.
///
/// - Tip: For more information, refer to the documentation of the `LLMSession` from SpeziLLM.
///
/// ## Streams
/// - ``generate()``: Starts a text response and returns an `AsyncThrowingStream` of token deltas. Finishes when the response completes.
/// - ``listen()``: Returns an `AsyncThrowingStream` of PCM16 audio (24 kHz sample rate) for the assistant's speech output. Lasts for the lifetime of the session.
///
/// ### Usage
///
/// The example below demonstrates a minimal usage of the ``LLMOpenAIRealtimeSession`` via the `LLMRunner`.
///
/// ```swift
/// import SpeziLLM
/// import SpeziLLMOpenAIRealtime
/// import SwiftUI
///
/// struct LLMOpenAIRealtimeDemoView: View {
///     @Environment(LLMRunner.self) var runner
///     @State var responseText = ""
///
///     var body: some View {
///         Text(responseText)
///             .task {
///                 // Instantiate the `LLMOpenAIRealtimeSchema` to an `LLMOpenAIRealtimeSession` via the `LLMRunner`.
///                 let llmSession: LLMOpenAIRealtimeSession = runner(
///                     with: LLMOpenAIRealtimeSchema(
///                         parameters: .init(
///                             modelType: .gpt_realtime,
///                             systemPrompt: "You're a helpful assistant that answers questions from users.",
///                             turnDetectionSettings: .semantic(),
///                             transcriptionSettings: .init(model: .gpt4oTranscribe)
///                         )
///                     )
///                 )
///
///                 do {
///                     for try await token in try await llmSession.generate() {
///                         responseText.append(token)
///                     }
///                 } catch {
///                     // Handle errors here. E.g., you can use `ViewState` and `viewStateAlert` from SpeziViews.
///                 }
///             }
///     }
/// }
/// ```
///
/// User audio input can be provided via ``appendUserAudio(_:)`` with 24 kHz PCM16 data.
/// When ``LLMRealtimeTurnDetectionSettings`` is configured through ``LLMOpenAIRealtimeParameters``, calling ``endUserTurn()`` is not required.
/// Otherwise, ``endUserTurn()`` can be used to explicitly trigger an assistant response.
///
/// The assistant's audio can be obtained as PCM16 at 24 kHz by calling ``listen()``:
/// ```swift
/// for try await pcm16 in try await llmSession.listen() {
///     someAudioBuffer.append(pcm16)
/// }
/// ```
@Observable
public final class LLMOpenAIRealtimeSession: LLMSession, SchemaProvidingLLMSession, Sendable {
    /// A Swift Logger that logs important information from the ``LLMOpenAIRealtimeSession``.
    package static let logger = Logger(subsystem: "edu.stanford.spezi", category: "SpeziLLMOpenAIRealtime")

    let platform: LLMOpenAIRealtimePlatform
    package let schema: LLMOpenAIRealtimeSchema
    let keychainStorage: KeychainStorage
    
    /// Handles websockets connection with OpenAI Realtime API
    let apiConnection = LLMOpenAIRealtimeConnection()

    @MainActor public var state: LLMState = .uninitialized
    @MainActor public var context: LLMContext = []
    let setupSemaphore = AsyncSemaphore(value: 1) // Max 1 task setting up
    package let toolCallCounter = Atomics.ManagedAtomic<Int>(0)
    package let toolCallCompletionState = LLMState.ready

    /// Creates an instance of a ``LLMOpenAISession`` responsible for LLM inference.
    ///
    /// - Parameters:
    ///   - platform: Reference to the ``LLMOpenAIRealtimePlatform`` where the ``LLMOpenAIRealtimeSession`` is running on.
    ///   - schema: The configuration of the OpenAI LLM expressed by the ``LLMOpenAIRealtimeSchema``.
    ///   - keychainStorage: Reference to the `KeychainStorage` from `SpeziStorage` in order to securely persist the token.
    ///
    /// - Important: Only the ``LLMOpenAIRealtimePlatform`` should create an instance of ``LLMOpenAIRealtimeSession``.
    init(_ platform: LLMOpenAIRealtimePlatform, schema: LLMOpenAIRealtimeSchema, keychainStorage: KeychainStorage) {
        self.platform = platform
        self.schema = schema
        self.keychainStorage = keychainStorage
    }

    /// Starts an assistant response and streams text deltas.
    ///
    /// This method sends the latest user message in the ``LLMOpenAIRealtimeSession/context`` to the Realtime API, then triggers the model to respond.
    /// It returns an `AsyncThrowingStream` that yields partial text tokens as they arrive until the Realtime API indicates the end of that transcript.
    ///
    /// - Returns: An `AsyncThrowingStream` of `String` token deltas. The stream finishes when the assistant transcript
    ///   completes or if the session is cancelled. Errors during setup or generation are propagated through the stream.
    @discardableResult
    public func generate() async -> AsyncThrowingStream<String, any Error> {
        typealias ResponseCreate = Components.Schemas.RealtimeClientEventResponseCreate
        typealias ConversationItemCreate = Components.Schemas.RealtimeClientEventConversationItemCreate

        // Stream the text response back to the `generate()` caller.
        // Is done by filtering assistant transcript events in `events()`.
        // Assumes that all events up to `.assistantTranscriptDone`
        // contain content belonging to the current `generate()` call.
        return AsyncThrowingStream { [apiConnection] continuation in
            let task = Task {
                do {
                    try await self.ensureSetup()

                    // Get the relevant part of the context
                    let lastContext = await self.context.last { $0.role == .user && $0.complete }

                    // Send the conversation.item.create event with the message
                    try await apiConnection.sendMessage(
                        ConversationItemCreate(
                            _type: .conversation_period_item_period_create,
                            item: .init(
                                _type: .message,
                                role: .user,
                                content: [.init(_type: .input_text, text: lastContext?.content ?? "")]
                            )
                        )
                    )

                    // Trigger a response
                    try await apiConnection.sendMessage(ResponseCreate(_type: .response_period_create))

                    for try await event in await apiConnection.events() {
                        if case .assistantTranscriptDone = event {
                            // Finish as soon as the next transcript done event occurs
                            continuation.finish()
                        }

                        if case .assistantTranscriptDelta(let delta) = event {
                            continuation.yield(delta)
                        }
                    }
                    continuation.finish() // in case `events()` stream finished
                } catch {
                    continuation.finish(throwing: error) // propagate upstream error
                }
            }

            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
    
    /// Closes the realtime connection.
    ///
    /// Calling this function ends any active streams.
    public func cancel() {
        Task { [apiConnection] in await apiConnection.cancel() }
    }

    deinit {
        self.cancel()
    }
}
