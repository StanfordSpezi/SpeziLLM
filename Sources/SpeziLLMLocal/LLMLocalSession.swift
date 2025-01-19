//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


import Foundation
import MLX
import MLXLLM
import MLXRandom
import os
import SpeziChat
import SpeziLLM


/// Represents an ``LLMLocalSchema`` in execution.
///
/// The ``LLMLocalSession`` is the executable version of the local LLM containing context and state as defined by the ``LLMLocalSchema``.
/// It utilizes the [llama.cpp library](https://github.com/ggerganov/llama.cpp) to locally execute a large language model on-device.
///
/// The inference is started by ``LLMLocalSession/generate()``, returning an `AsyncThrowingStream` and can be cancelled via ``LLMLocalSession/cancel()``.
/// The ``LLMLocalSession`` exposes its current state via the ``LLMLocalSession/context`` property, containing all the conversational history with the LLM.
///
/// - Warning: The ``LLMLocalSession`` shouldn't be created manually but always through the ``LLMLocalPlatform`` via the `LLMRunner`.
///
/// - Important: In order to use the LLM local target, one needs to set build parameters in the consuming Xcode project or the consuming SPM package to enable the [Swift / C++ Interop](https://www.swift.org/documentation/cxx-interop/),     <!-- markdown-link-check-disable-line -->
/// introduced in Xcode 15 and Swift 5.9. Please refer to <doc:SpeziLLMLocal#Setup> for more information.
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
public final class LLMLocalSession: LLMSession, @unchecked Sendable {
    /// A Swift Logger that logs important information from the ``LLMLocalSession``.
    static let logger = Logger(subsystem: "edu.stanford.spezi", category: "SpeziLLMLocal")
    
    let platform: LLMLocalPlatform
    var schema: LLMLocalSchema
    
    @ObservationIgnored private var modelExist: Bool {
        false
    }
    
    /// A task managing the ``LLMLocalSession`` output generation.
    @ObservationIgnored private var task: Task<(), Never>?
    
    @MainActor public var state: LLMState = .uninitialized
    @MainActor public var context: LLMContext = []
    /// Overrides the `context` with a custom highly customizable context in the `swift-transformers` format.
    /// - Important: When using the `customContext`, `injectToContext` will have no effect, and the assistant output will **not** be added to the `customContext`
    @MainActor public var customContext: [[String: String]] = []
    
    @MainActor public var numParameters: Int?
    @MainActor public var modelConfiguration: ModelConfiguration?
    @MainActor public var modelContainer: ModelContainer?
    
    
    /// Creates an instance of a ``LLMLocalSession`` responsible for LLM inference.
    /// Only the ``LLMLocalPlatform`` should create an instance of ``LLMLocalSession``.
    ///
    /// - Parameters:
    ///     - platform: Reference to the ``LLMLocalPlatform`` where the ``LLMLocalSession`` is running on.
    ///     - schema: The configuration of the local LLM expressed by the ``LLMLocalSchema``.
    init(_ platform: LLMLocalPlatform, schema: LLMLocalSchema) {
        self.platform = platform
        self.schema = schema
        
        // Inject system prompt into context
        if let systemPrompt = schema.parameters.systemPrompt {
            Task { @MainActor in
                context.append(systemMessage: systemPrompt)
            }
        }
    }
    
    /// Initializes the model in advance.
    /// Calling this method before user interaction prepares the model, which leads to reduced response time for the first prompt.
    public func setup() async throws {
        guard await _setup(continuation: nil) else {
            throw LLMLocalError.modelNotReadyYet
        }
    }
    
    /// Releases the memory associated with the current model.
    ///
    /// This function frees up memory resources by clearing the model container and reset the GPU cache, allowing to e.g. load a different model.
    public func offload() async {
        await MainActor.run {
            modelContainer = nil
        }
        MLX.GPU.clearCache()
    }
    
    
    /// Based on the input prompt, generate the output.
    /// - Returns: A Swift `AsyncThrowingStream` that streams the generated output.
    @discardableResult
    public func generate() async throws -> AsyncThrowingStream<String, Error> {
        let (stream, continuation) = AsyncThrowingStream.makeStream(of: String.self)
        
        task = Task(priority: platform.configuration.taskPriority) {
            if await state == .uninitialized {
                guard await _setup(continuation: continuation) else {
                    await MainActor.run {
                        state = .error(error: LLMLocalError.modelNotReadyYet)
                    }
                    await finishGenerationWithError(LLMLocalError.modelNotReadyYet, on: continuation)
                    return
                }
            }
            
            guard await !checkCancellation(on: continuation) else {
                return
            }
            
            await MainActor.run {
                self.state = .generating
            }
            
            // Execute the output generation of the LLM
            await _generate(continuation: continuation)
        }
        
        return stream
    }
    
    
    public func cancel() {
        task?.cancel()
    }
    
    deinit {
        cancel()
    }
}
