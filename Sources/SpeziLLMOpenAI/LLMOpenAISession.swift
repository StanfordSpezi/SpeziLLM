//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import struct OpenAI.Chat
import struct OpenAI.ChatFunctionDeclaration
import struct OpenAI.ChatQuery
import class OpenAI.OpenAI
import struct OpenAI.Model
import struct OpenAI.ChatStreamResult
import struct OpenAI.APIErrorResponse
import os
import SpeziChat
import SpeziLLM
import SpeziSecureStorage


@Observable
public class LLMOpenAISession: LLMSession {
    /// A Swift Logger that logs important information from the ``LLMOpenAISession``.
    static let logger = Logger(subsystem: "edu.stanford.spezi", category: "SpeziLLMOpenAI")
    
    
    let platform: LLMOpenAIPlatform
    let schema: LLMOpenAISchema
    let secureStorage: SecureStorage
    
    /// A task managing the ``LLMOpenAISession`` output generation.
    private var task: Task<(), Never>?
    
    @MainActor public var state: LLMState = .uninitialized
    @MainActor public var context: SpeziChat.Chat = []
    @ObservationIgnored var wrappedModel: OpenAI?
    
    var model: OpenAI {
        guard let model = wrappedModel else {
            preconditionFailure("""
            SpeziLLMOpenAI: Illegal Access - Tried to access the wrapped OpenAI model of `LLMOpenAI` before being initialized.
            Ensure that the `LLMOpenAIRunnerSetupTask` is passed to the `LLMRunner` within the Spezi `Configuration`.
            """)
        }
        return model
    }
    
    
    init(_ platform: LLMOpenAIPlatform, schema: LLMOpenAISchema, secureStorage: SecureStorage) {
        self.platform = platform
        self.schema = schema
        self.secureStorage = secureStorage
        
        // Inject system prompt into context
        Task { @MainActor in
            context.append(systemMessage: schema.parameters.systemPrompt)
        }
    }
    
    
    @discardableResult
    public func generate() async throws -> AsyncThrowingStream<String, Error> {
        try await platform.register()
        try Task.checkCancellation()
        
        let (stream, continuation) = AsyncThrowingStream.makeStream(of: String.self)
        
        // Execute the output generation of the LLM
        task = Task(priority: platform.configuration.taskPriority) {
            // Unregister as soon as `Task` finishes
            defer {
                Task {
                    await platform.unregister()
                }
            }
            
            // Setup the model, if not already done
            if wrappedModel == nil {
                guard await setup(continuation: continuation) else {
                    return
                }
            }
            
            guard await !checkCancellation(on: continuation) else {
                return
            }
            
            // Execute the inference
            await _generate(continuation: continuation)
        }
        
        return stream
    }
    
    public func cancel() {
        task?.cancel()
    }
    
    
    deinit {
        task?.cancel()
    }
}
