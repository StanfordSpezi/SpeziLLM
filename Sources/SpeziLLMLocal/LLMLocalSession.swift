//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import os
import SpeziChat
import SpeziLLM


@Observable
public class LLMLocalSession: LLMSession {
    /// A Swift Logger that logs important information from the ``LLMLocal``.
    static let logger = Logger(subsystem: "edu.stanford.spezi", category: "SpeziLLMLocal")
    
    
    let platform: LLMLocalPlatform
    let schema: LLMLocalSchema
    
    /// A task managing the ``LLMLocalSession`` output generation.
    private var task: Task<(), Never>?
    
    @MainActor public var state: LLMState = .uninitialized
    @MainActor public var context: Chat = []
    
    /// A pointer to the allocated model via llama.cpp.
    @ObservationIgnored var model: OpaquePointer?
    /// A pointer to the allocated model context from llama.cpp.
    @ObservationIgnored var modelContext: OpaquePointer?
    
    
    init(_ platform: LLMLocalPlatform, schema: LLMLocalSchema) {
        self.platform = platform
        self.schema = schema
        
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
            if model == nil {
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
