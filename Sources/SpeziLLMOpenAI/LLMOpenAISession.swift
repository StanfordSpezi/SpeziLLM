//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import OpenAPIRuntime
import OpenAPIURLSession
import os
import SpeziChat
import SpeziLLM
import SpeziSecureStorage


/// Represents an ``LLMOpenAISchema`` in execution.
///
/// The ``LLMOpenAISession`` is the executable version of the OpenAI LLM containing context and state as defined by the ``LLMOpenAISchema``.
/// It provides access to text-based models from OpenAI, such as GPT-3.5 or GPT-4.
///
/// The inference is started by ``LLMOpenAISession/generate()``, returning an `AsyncThrowingStream` and can be cancelled via ``LLMOpenAISession/cancel()``.
/// The ``LLMOpenAISession`` exposes its current state via the ``LLMOpenAISession/context`` property, containing all the conversational history with the LLM.
///
/// - Warning: The ``LLMOpenAISession`` shouldn't be created manually but always through the ``LLMOpenAIPlatform`` via the `LLMRunner`.
///
/// - Tip: ``LLMOpenAISession`` also enables the function calling mechanism to establish a structured, bidirectional, and reliable communication between the OpenAI LLMs and external tools. For details, refer to ``LLMFunction`` and ``LLMFunction/Parameter`` or the <doc:FunctionCalling> DocC article.
///
/// - Tip: For more information, refer to the documentation of the `LLMSession` from SpeziLLM.
///
/// ### Usage
///
/// The example below demonstrates a minimal usage of the ``LLMOpenAISession`` via the `LLMRunner`.
///
/// ```swift
/// struct LLMOpenAIDemoView: View {
///     @Environment(LLMRunner.self) var runner
///     @State var responseText = ""
///
///     var body: some View {
///         Text(responseText)
///             .task {
///                 // Instantiate the `LLMOpenAISchema` to an `LLMOpenAISession` via the `LLMRunner`.
///                 let llmSession: LLMOpenAISession = runner(
///                     with: LLMOpenAISchema(
///                         parameters: .init(
///                             modelType: .gpt3_5Turbo,
///                             systemPrompt: "You're a helpful assistant that answers questions from users.",
///                             overwritingToken: "abc123"
///                         )
///                     )
///                 )
///
///                 for try await token in try await llmSession.generate() {
///                     responseText.append(token)
///                 }
///             }
///     }
/// }
/// ```
@Observable
public final class LLMOpenAISession: LLMSession, @unchecked Sendable {
    /// A Swift Logger that logs important information from the ``LLMOpenAISession``.
    static let logger = Logger(subsystem: "edu.stanford.spezi", category: "SpeziLLMOpenAI")
    
    
    let platform: LLMOpenAIPlatform
    let schema: LLMOpenAISchema
    let secureStorage: SecureStorage
    
    /// A set of `Task`s managing the ``LLMOpenAISession`` output generation.
    @ObservationIgnored private var tasks: Set<Task<(), Never>> = []
    /// Ensuring thread-safe access to the `LLMOpenAISession/task`.
    @ObservationIgnored private var lock = NSLock()
    
    @MainActor public var state: LLMState = .uninitialized
    @MainActor public var context: LLMContext = []
    @ObservationIgnored var wrappedClient: Client?

    var chatGPTClient: Client {
        guard let chatGPTClient = wrappedClient else {
            preconditionFailure("""
            SpeziLLMOpenAI: Illegal Access - Tried to access the wrapped OpenAI client of `LLMOpenAISession` before being initialized.
            Ensure that the `LLMOpenAIPlatform` is passed to the `LLMRunner` within the Spezi `Configuration`.
            """)
        }
        return chatGPTClient
    }
    
    
    /// Creates an instance of a ``LLMOpenAISession`` responsible for LLM inference.
    /// Only the ``LLMOpenAIPlatform`` should create an instance of ``LLMOpenAISession``.
    ///
    /// - Parameters:
    ///     - platform: Reference to the ``LLMOpenAIPlatform`` where the ``LLMOpenAISession`` is running on.
    ///     - schema: The configuration of the OpenAI LLM expressed by the ``LLMOpenAISchema``.
    ///     - secureStorage: Reference to the `SecureStorage` from `SpeziStorage` in order to securely persist the token.
    init(_ platform: LLMOpenAIPlatform, schema: LLMOpenAISchema, secureStorage: SecureStorage) {
        self.platform = platform
        self.schema = schema
        self.secureStorage = secureStorage
        
        // Inject system prompts into context
        Task { @MainActor in
            schema.parameters.systemPrompts.forEach { systemPrompt in
                context.append(systemMessage: systemPrompt)
            }
        }
    }
    
    
    @discardableResult
    public func generate() async throws -> AsyncThrowingStream<String, Error> {
        try await platform.exclusiveAccess()
        
        let (stream, continuation) = AsyncThrowingStream.makeStream(of: String.self)
        
        // Execute the output generation of the LLM
        let task = Task(priority: platform.configuration.taskPriority) {
            // Unregister as soon as `Task` finishes
            defer {
                Task {
                    await platform.signal()
                }
            }
            
            // Setup the model, if not already done
            if wrappedClient == nil {
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
        
        _ = lock.withLock {
            tasks.insert(task)
        }
        
        return stream
    }
    
    public func cancel() {
        lock.withLock {
            for task in tasks {
                task.cancel()
            }
        }
    }
    
    
    deinit {
        cancel()
    }
}
