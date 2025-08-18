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
import SpeziKeychainStorage
import SpeziLLM


/// TODO
@Observable
public final class LLMOpenAIRealtimeSession: AudioCapableLLMSession, Sendable {
    /// A Swift Logger that logs important information from the ``LLMOpenAISession``.
    static let logger = Logger(subsystem: "edu.stanford.spezi", category: "SpeziLLMOpenAIRealtime")
    
//    let platform: LLMOpenAIPlatform
//    let schema: LLMOpenAISchema
//    let keychainStorage: KeychainStorage
    
    @MainActor public var state: LLMState = .uninitialized
    @MainActor public var context: LLMContext = []

    /// Holds the currently generating continuations so that we can cancel them if required.
    let continuationHolder = LLMInferenceQueueContinuationHolder()
    
    init() { }
    
    public func cancel() {
        // cancel all currently generating continuations
        self.continuationHolder.cancelAll()
    }
    
    @discardableResult
    public func generate() async throws -> AsyncThrowingStream<String, any Error> {
        let (stream, _) = AsyncThrowingStream.makeStream(of: String.self)
        
        return stream
    }
    
    func listen() -> AsyncThrowingStream<Data, any Error> {
        let (stream, _) = AsyncThrowingStream.makeStream(of: Data.self)
        
        return stream
    }
    
    public func appendUserAudio(_ buffer: Data) async throws {
        Self.logger.debug("appendUserAudio")
    }
    
    func endUserTurn() async throws {
    }
    
    func events() -> AsyncThrowingStream<LLMEvent, any Error> {
        let (stream, _) = AsyncThrowingStream.makeStream(of: LLMEvent.self)
        
        return stream
    }
    
    deinit {
        self.cancel()
    }
}


protocol AudioCapableLLMSession: LLMSession {
    func listen() -> AsyncThrowingStream<Data, any Error>
    
    func appendUserAudio(_ buffer: Data) async throws
    
    func endUserTurn() async throws
    
    func events() -> AsyncThrowingStream<LLMEvent, any Error>
}

enum LLMEvent {
    case textDelta(String)
    case toolCall(Data)
    case audioDelta(Data)
    case userTranscript(String)
    case assistantTranscript(String)
}
