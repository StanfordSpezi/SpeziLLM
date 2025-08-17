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
import SpeziFoundation
import SpeziKeychainStorage
import SpeziLLM


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
/// import SpeziLLM
/// import SpeziLLMOpenAI
/// import SwiftUI
///
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
///                             modelType: .gpt4o,
///                             systemPrompt: "You're a helpful assistant that answers questions from users.",
///                             overwritingToken: "abc123"
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
public final class LLMOpenAISession: LLMSession, Sendable {
    /// A Swift Logger that logs important information from the ``LLMOpenAISession``.
    static let logger = Logger(subsystem: "edu.stanford.spezi", category: "SpeziLLMOpenAI")
    
    
    let platform: LLMOpenAIPlatform
    let schema: LLMOpenAISchema
    let keychainStorage: KeychainStorage

    private let clientLock = RWLock()
    /// The wrapped client instance communicating with the OpenAI API
    @ObservationIgnored private nonisolated(unsafe) var wrappedClient: Client?
    /// Holds the currently generating continuations so that we can cancel them if required.
    let continuationHolder = LLMInferenceQueueContinuationHolder()

    @MainActor public var state: LLMState = .uninitialized
    @MainActor public var context: LLMContext = []

    var openAiClient: Client {
        get {
            let client = self.clientLock.withReadLock { self.wrappedClient }

            guard let client else {
                fatalError("""
                SpeziLLMOpenAI: Illegal Access - Tried to access the wrapped OpenAI client of `LLMOpenAISession` before being initialized.
                Ensure that the `LLMOpenAIPlatform` is passed to the `LLMRunner` within the Spezi `Configuration`.
                """)
            }
            return client
        }

        set {
            self.clientLock.withWriteLock {
                self.wrappedClient = newValue
            }
        }
    }
    
    
    /// Creates an instance of a ``LLMOpenAISession`` responsible for LLM inference.
    ///
    /// - Parameters:
    ///   - platform: Reference to the ``LLMOpenAIPlatform`` where the ``LLMOpenAISession`` is running on.
    ///   - schema: The configuration of the OpenAI LLM expressed by the ``LLMOpenAISchema``.
    ///   - keychainStorage: Reference to the `KeychainStorage` from `SpeziStorage` in order to securely persist the token.
    ///
    /// - Important: Only the ``LLMOpenAIPlatform`` should create an instance of ``LLMOpenAISession``.
    init(_ platform: LLMOpenAIPlatform, schema: LLMOpenAISchema, keychainStorage: KeychainStorage) {
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
            // starts tracking the continuation for cancellation
            let continuationObserver = ContinuationObserver(track: continuation)
            defer {
                // To be on the safe side, finish the continuation (has no effect if multiple finish calls)
                continuationObserver.continuation.finish()
            }

            // Retains the continuation during inference for potential cancellation
            await self.continuationHolder.withContinuationHold(continuation: continuation) {
                if continuationObserver.isCancelled {
                    Self.logger.warning("SpeziLLMOpenAI: Generation cancelled by the user.")
                    return
                }

                // Setup the model, if not already done
                if self.wrappedClient == nil {
                    guard await self.setup(with: continuationObserver) else {
                        return
                    }
                }

                // Execute the inference
                await self._generate(with: continuationObserver)
            }
        }
    }
    
    public func cancel() {
        // cancel all currently generating continuations
        self.continuationHolder.cancelAll()
    }
    
    
    deinit {
        self.cancel()
    }
}
