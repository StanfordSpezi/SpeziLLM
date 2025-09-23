//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import GeneratedOpenAIClient
import OpenAPIRuntime
import OpenAPIURLSession
import os
import SpeziChat
import SpeziFoundation
import SpeziKeychainStorage
import SpeziLLM


@Observable
public final class LLMOpenAIRealtimeSession: LLMSession, Sendable {
    /// A Swift Logger that logs important information from the ``LLMOpenAIRealtimeSession``.
    static let logger = Logger(subsystem: "edu.stanford.spezi", category: "SpeziLLMOpenAIRealtime")

    let platform: LLMOpenAIRealtimePlatform
    let schema: LLMOpenAIRealtimeSchema
    let keychainStorage: KeychainStorage
    
    /// Handles websockets connection with OpenAI Realtime API
    let apiConnection = LLMOpenAIRealtimeConnection()

    @MainActor public var state: LLMState = .uninitialized
    @MainActor public var context: LLMContext = []
    let setupSemaphore = AsyncSemaphore(value: 1) // Max 1 task setting up

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

    /// Generates the text results that get appended to the context, based on the text. And if you're listening to the stream via `listen()` then you'll also get the audio output
    /// Note that if you were speaking into the microphone until that point and sending that with appendUserAudio(), this also gets included when calling generate() here
    @discardableResult
    public func generate() async throws -> AsyncThrowingStream<String, any Error> {
        typealias ResponseCreate = Components.Schemas.RealtimeClientEventResponseCreate
        typealias ConversationItemCreate = Components.Schemas.RealtimeClientEventConversationItemCreate

        guard try await ensureSetup() else {
            return AsyncThrowingStream { continuation in
                continuation.finish()
            }
        }
        
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

        
        // Stream the text response back to the `generate()` caller.
        // Is done by filtering assistant transcript events in `events()`.
        // Assumes that all events up to `.assistantTranscriptDone`
        // contain content belonging to the current `generate()` call.
        return AsyncThrowingStream { [apiConnection] continuation in
            let task = Task {
                do {
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
    
    public func cancel() {
        Task { [apiConnection] in await apiConnection.cancel() }
    }

    deinit {
        self.cancel()
    }
}
