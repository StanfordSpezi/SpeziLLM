//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
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
@Observable
public final class LLMFogSession: LLMSession, Sendable {
    /// A Swift Logger that logs important information from the ``LLMFogSession``.
    static let logger = Logger(subsystem: "edu.stanford.spezi", category: "SpeziLLMFog")
    
    
    let platform: LLMFogPlatform
    let schema: LLMFogSchema
    let keychainStorage: KeychainStorage

    private let clientLock = NSLock()
    /// The wrapped client instance communicating with the Fog LLM.
    @ObservationIgnored private nonisolated(unsafe) var wrappedClient: Client?
    /// Holds the currently generating continuations so that we can cancel them if required.
    let continuationHolder = LLMInferenceQueueContinuationHolder()

    @MainActor public var state: LLMState = .uninitialized
    @MainActor public var context: LLMContext = []
    /// Discovered fog node advertising the LLM inference service.
    @MainActor public var discoveredServiceAddress: String?

    var fogNodeClient: Client {
        get {
            let client = self.clientLock.withLock { self.wrappedClient }

            guard let client else {
                fatalError("""
                SpeziLLMFog: Illegal Access - Tried to access the wrapped Fog LLM client of `LLMFogSession` before being initialized.
                Ensure that the `LLMFogPlatform` is passed to the `LLMRunner` within the Spezi `Configuration`.
                """)
            }
            return client
        }

        set {
            self.clientLock.withLock {
                self.wrappedClient = newValue
            }
        }
    }

    
    /// Creates an instance of a ``LLMFogSession`` responsible for LLM inference.
    ///
    /// Only the ``LLMFogPlatform`` should create an instance of ``LLMFogSession``.
    ///
    /// - Parameters:
    ///    - platform: Reference to the ``LLMFogPlatform`` where the ``LLMFogSession`` is running on.
    ///    - schema: The configuration of the Fog LLM expressed by the ``LLMFogSchema``.
    ///    - keychainStorage: The `KeychainStorage` module to potentially read the auth token from.
    init(_ platform: LLMFogPlatform, schema: LLMFogSchema, keychainStorage: KeychainStorage) {
        self.platform = platform
        self.schema = schema
        self.keychainStorage = keychainStorage
    }
    
    
    @discardableResult
    public func generate() async throws -> AsyncThrowingStream<String, any Error> {
        // Inject system prompts into context
        if await self.context.isEmpty {
            await MainActor.run {
                for prompt in self.schema.parameters.systemPrompts {
                    self.context.append(systemMessage: prompt)
                }
            }
        }

        return try self.platform.queue.submit { continuation in
            // store the continuation so that we can cancel it later
            let id = self.continuationHolder.add(continuation)
            
            // Setup the fog LLM, if not already done
            guard await self.setup(continuation: continuation),
                  await !self.checkCancellation(on: continuation) else {
                return
            }

            // Execute the inference
            await self._generate(continuation: continuation)

            // remove continuation from holder (does not cancel it)
            self.continuationHolder.remove(id: id)
        }
    }
    
    public func setup(
        continuation: AsyncThrowingStream<String, any Error>.Continuation = AsyncThrowingStream.makeStream(of: String.self).continuation
    ) async -> Bool {
        // Setup the model, if not already done
        if self.wrappedClient == nil {
            guard await self._setup(continuation: continuation) else {
                return false
            }
        }
        
        return true
    }
    
    public func cancel() {
        // cancel all currently generating continuations
        self.continuationHolder.cancelAll()
    }
    
    
    deinit {
        self.cancel()
    }
}
