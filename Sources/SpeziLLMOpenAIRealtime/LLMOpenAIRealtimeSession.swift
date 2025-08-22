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
        print("Generate() got called ")
        let currentState = await state
        if currentState == .ready || currentState == .loading {
            let (stream, continuation) = AsyncThrowingStream.makeStream(of: String.self)
            continuation.finish()
            return stream
        }

        // 1. Send the relevant context as text to OpenAI
        // 2. Probably here we generate and return a new stream, which is active until the next response.done. The stream returns content += string deltas
        //    like LLMOpenAISession, so that it can be used inside ChatView.
        //
        // Listening to `self.event()` would probably be smart here, to avoid re-inventing the wheel.
        _ = try await ensureSetup()

        // TODO: Handle text messages (appends to context) correctly by sending the transcript of the response back here in generate()
        let (stream, continuation) = AsyncThrowingStream.makeStream(of: String.self)
        continuation.finish()
        return stream
    }
    
    public func cancel() {
        print("LLMOpenAIRealtimeSession: Cancelling!")
        Task { [apiConnection] in await apiConnection.cancel() }
    }

    deinit {
        self.cancel()
    }
}
