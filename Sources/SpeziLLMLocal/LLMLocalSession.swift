//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


import Foundation
import Hub
import MLX
import MLXLLM
import MLXLMCommon
import MLXRandom
import os
import SpeziChat
import SpeziLLM


/// Represents an ``LLMLocalSchema`` in execution.
///
/// The ``LLMLocalSession`` is the executable version of the local LLM containing context and state as defined by the ``LLMLocalSchema``.
/// It utilizes [MLX Swift](https://github.com/ml-explore/mlx-swift) to locally execute a large language model on-device.
///
/// The inference is started by ``LLMLocalSession/generate()``, returning an `AsyncThrowingStream` and can be cancelled via ``LLMLocalSession/cancel()``.
/// The ``LLMLocalSession`` exposes its current state via the ``LLMLocalSession/context`` property, containing all the conversational history with the LLM.
///
/// To offload the model and to free occupied resources by the LLM when not in use, ``LLMLocalSession/offload()`` can be called.
///
/// - Warning: The ``LLMLocalSession`` shouldn't be created manually but always through the ``LLMLocalPlatform`` via the `LLMRunner`.
///
/// - Tip: For more information, refer to the documentation of the `LLMSession` from SpeziLLM.
///
/// ### Usage
///
/// The example below demonstrates a minimal usage of the ``LLMLocalSession`` via the `LLMRunner`.
///
/// ```swift
/// struct LLMLocalDemoView: View {
///     @Environment(LLMRunner.self) var runner
///     @State var responseText = ""
///
///     var body: some View {
///         Text(responseText)
///             .task {
///                 // Instantiate the `LLMLocalSchema` to an `LLMLocalSession` via the `LLMRunner`.
///                 let llmSession: LLMLocalSession = runner(
///                     with: LLMLocalSchema(
///                         modelPath: URL(string: "URL to the local model file")!
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
public final class LLMLocalSession: LLMSession, Sendable {
    /// A Swift Logger that logs important information from the ``LLMLocalSession``.
    static let logger = Logger(subsystem: "edu.stanford.spezi", category: "SpeziLLMLocal")
    /// The HuggingFace Hub API client.
    package static let hubApi = HubApi(downloadBase: FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first)

    let platform: LLMLocalPlatform
    let schema: LLMLocalSchema

    /// Holds the currently generating continuations so that we can cancel them if required.
    let continuationHolder = LLMInferenceQueueContinuationHolder()

    @MainActor public var state: LLMState = .uninitialized
    @MainActor public var context: LLMContext = []
    /// Overrides the `context` with a custom highly customizable context in the `swift-transformers` format.
    /// - Important: When using the `customContext`, `injectToContext` will have no effect, and the assistant output will **not** be added to the `customContext`
    @MainActor public var customContext: [[String: String]] = []
    
    @MainActor public var numParameters: Int?
    @MainActor public var modelConfiguration: LLMRegistry?
    @MainActor public var modelContainer: ModelContainer?

    
    /// Creates an instance of a ``LLMLocalSession`` responsible for LLM inference.
    ///
    /// - Parameters:
    ///    - platform: Reference to the ``LLMLocalPlatform`` where the ``LLMLocalSession`` is running on.
    ///    - schema: The configuration of the local LLM expressed by the ``LLMLocalSchema``.
    ///
    /// - Important: Only the ``LLMLocalPlatform`` should create an instance of ``LLMLocalSession``.
    init(_ platform: LLMLocalPlatform, schema: LLMLocalSchema) {
        self.platform = platform
        self.schema = schema
    }
    
    /// Initializes the model in advance.
    ///
    /// Calling this method before user interaction prepares the model, which leads to reduced response time for the first prompt.
    public func setup() async throws {
        guard await _setup(continuation: nil) else {
            throw LLMLocalError.modelNotReadyYet
        }
    }
    
    /// Releases the resources associated with the current ``LLMLocalSession``.
    ///
    /// Frees up memory resources by clearing the model container and reset the GPU cache, allowing to e.g. load a different local model.
    public func offload() async {
        self.cancel()
        await MainActor.run {
            modelContainer = nil
            state = .uninitialized
        }
        MLX.GPU.clearCache()
    }
    
    
    /// Based on the input prompt, generate the output.
    /// - Returns: A Swift `AsyncThrowingStream` that streams the generated output.
    @discardableResult
    public func generate() async throws -> AsyncThrowingStream<String, any Error> {
        // Inject system prompts into context
        if await self.context.isEmpty {
            await MainActor.run {
                if let prompt = self.schema.parameters.systemPrompt {
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
                    Self.logger.warning("SpeziLLMLocal: Generation cancelled by the user.")
                    return
                }

                if await self.state == .uninitialized {
                    guard await self._setup(continuation: continuation) else {
                        await MainActor.run {
                            self.state = .error(error: LLMLocalError.modelNotReadyYet)
                        }
                        await self.finishGenerationWithError(LLMLocalError.modelNotReadyYet, on: continuation)
                        return
                    }
                }

                // Execute the output generation of the LLM
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
