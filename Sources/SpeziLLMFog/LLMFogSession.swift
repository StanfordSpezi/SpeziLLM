//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import class OpenAI.OpenAI
import os
import SpeziChat
import SpeziLLM


/// Represents an ``LLMFogSchema`` in execution.
///
/// The ``LLMFogSession`` is the executable version of a Fog LLM containing context and state as defined by the ``LLMFogSchema``.
/// It provides access to text-based models from the Fog LLM resource, such as Llama2 or Gemma.
///
/// As the to-be-used models are running on a Fog node within the local network, the respective LLM computing resource (so the fog node) is discovered upon setup of the ``LLMFogSession``, meaning a ``LLMFogSession`` is bound to a specific fog node after initialization.
///
/// The inference is started by ``LLMFogSession/generate()``, returning an `AsyncThrowingStream` and can be cancelled via ``LLMFogSession/cancel()``.
/// Additionally, one is able to force the setup of the ``LLMFogSession`` (so discovering the respective fog LLM service) via ``LLMFogSession/setup(continuation:)``.
/// The ``LLMFogSession`` exposes its current state via the ``LLMFogSession/context`` property, containing all the conversational history with the LLM.
///
/// - Warning: The ``LLMFogSession`` shouldn't be created manually but always through the ``LLMFogPlatform`` via the `LLMRunner`.
///
/// - Tip: For more information, refer to the documentation of the `LLMSession` from SpeziLLM.
///
/// ### Usage
///
/// The example below demonstrates a minimal usage of the ``LLMFogSession`` via the `LLMRunner`.
///
/// ```swift
/// struct LLMFogDemoView: View {
///     @Environment(LLMRunner.self) var runner
///     @State var responseText = ""
///
///     var body: some View {
///         Text(responseText)
///             .task {
///                 // Instantiate the `LLMFogSchema` to an `LLMFogSession` via the `LLMRunner`.
///                 let llmSession: LLMFogSession = runner(
///                     with: LLMFogSchema(
///                         parameters: .init(
///                             modelType: .llama7B,
///                             systemPrompt: "You're a helpful assistant that answers questions from users."
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
public final class LLMFogSession: LLMSession, @unchecked Sendable {
    /// A Swift Logger that logs important information from the ``LLMFogSession``.
    static let logger = Logger(subsystem: "edu.stanford.spezi", category: "SpeziLLMFog")
    
    
    let platform: LLMFogPlatform
    let schema: LLMFogSchema
    
    /// A set of `Task`s managing the ``LLMFogSession`` output generation.
    @ObservationIgnored private var tasks: Set<Task<(), Never>> = []
    /// Ensuring thread-safe access to the `LLMFogSession/task`.
    @ObservationIgnored private var lock = NSLock()
    /// The wrapped client instance communicating with the Fog LLM
    @ObservationIgnored var wrappedModel: OpenAI?
    /// Discovered fog node advertising the LLM inference service
    @ObservationIgnored var discoveredServiceAddress: String?
    
    @MainActor public var state: LLMState = .uninitialized
    @MainActor public var context: LLMContext = []
    
    
    var model: OpenAI {
        guard let model = wrappedModel else {
            preconditionFailure("""
            SpeziLLMFog: Illegal Access - Tried to access the wrapped Fog LLM model of `LLMFogSession` before being initialized.
            Ensure that the `LLMFogPlatform` is passed to the `LLMRunner` within the Spezi `Configuration`.
            """)
        }
        return model
    }
    
    
    /// Creates an instance of a ``LLMFogSession`` responsible for LLM inference.
    /// Only the ``LLMFogPlatform`` should create an instance of ``LLMFogSession``.
    ///
    /// - Parameters:
    ///    - platform: Reference to the ``LLMFogPlatform`` where the ``LLMFogSession`` is running on.
    ///    - schema: The configuration of the Fog LLM expressed by the ``LLMFogSchema``.
    init(_ platform: LLMFogPlatform, schema: LLMFogSchema) {
        self.platform = platform
        self.schema = schema
        
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
            
            // Setup the fog LLM, if not already done
            guard await setup(continuation: continuation),
                  await !checkCancellation(on: continuation) else {
                return
            }
            
            // Get fresh auth token
            wrappedModel?.configuration.token = await schema.parameters.authToken()
            
            // Execute the inference
            await _generate(continuation: continuation)
        }
        
        _ = lock.withLock {
            tasks.insert(task)
        }
        
        return stream
    }
    
    public func setup(
        continuation: AsyncThrowingStream<String, Error>.Continuation = AsyncThrowingStream.makeStream(of: String.self).continuation
    ) async -> Bool {
        // Setup the model, if not already done
        if wrappedModel == nil {
            guard await _setup(continuation: continuation) else {
                return false
            }
        }
        
        return true
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
