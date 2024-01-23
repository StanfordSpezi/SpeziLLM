//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import llama
import os
import SpeziChat
import SpeziLLM


/// Enables the local execution of Spezi `LLM`s.
///
/// The ``LLMLocal`` is a Spezi `LLM` and utilizes the [llama.cpp library](https://github.com/ggerganov/llama.cpp) to locally execute a large language model on-device.
/// The main properties of the ``LLMLocal`` are ``LLMLocal/context`` and ``LLMLocal/state``. Use these properties to access the conversational history of the `LLM` as well as the current generation state.
///
/// - Important: ``LLMLocal`` shouldn't be used on it's own but always wrapped by the Spezi `LLMRunner` as the runner handles
/// all management overhead tasks. A code example on how to use ``LLMLocal`` in combination with the `LLMRunner` can be
/// found in the documentation of the `LLMRunner`.
///
/// - Important: If one uses the `SpeziLLMLocal` target within an Xcode application, ensure to set the following ["Build Setting" of the respective target](https://developer.apple.com/documentation/xcode/configuring-the-build-settings-of-a-target/): `C++ and Objective-C interoperability` to `C++ / Objective-C++`. Otherwise, your application won't compile and you'll get complex compile error.
/// On the other hand, if one uses `SpeziLLMLocal` within an [SPM package](https://www.swift.org/documentation/package-manager/), ensure to properly set the `swiftSettings` of the consuming target to `swiftSettings: [.interoperabilityMode(.Cxx)]`.
@Observable
public class LLMLocal: LLM {
    /// A Swift Logger that logs important information from the ``LLMLocal``.
    static let logger = Logger(subsystem: "edu.stanford.spezi", category: "SpeziLLM")
    public let type: LLMHostingType = .local
    @MainActor public var state: LLMState = .uninitialized
    @MainActor public var context: Chat = []
    
    /// Parameters of the llama.cpp ``LLM``.
    let parameters: LLMLocalParameters
    /// Context parameters of the llama.cpp ``LLM``.
    let contextParameters: LLMLocalContextParameters
    /// Sampling parameters of the llama.cpp ``LLM``.
    let samplingParameters: LLMLocalSamplingParameters
    /// The on-device `URL` where the model is located.
    private let modelPath: URL
    /// A pointer to the allocated model via llama.cpp.
    @ObservationIgnored var model: OpaquePointer?
    /// A pointer to the allocated model context from llama.cpp.
    @ObservationIgnored var modelContext: OpaquePointer?
    
    
    /// Creates a ``LLMLocal`` instance that can then be passed to the `LLMRunner` for execution.
    ///
    /// - Parameters:
    ///   - modelPath: A local `URL` where the LLM file is stored. The format of the LLM must be in the llama.cpp `.gguf` format.
    ///   - parameters: Parameterize the ``LLMLocal`` via ``LLMLocalParameters``.
    ///   - contextParameters: Configure the context of the ``LLMLocal`` via ``LLMLocalContextParameters``.
    ///   - samplingParameters: Parameterize the sampling methods of the ``LLMLocal`` via ``LLMLocalSamplingParameters``.
    public init(
        modelPath: URL,
        parameters: LLMLocalParameters = .init(),
        contextParameters: LLMLocalContextParameters = .init(),
        samplingParameters: LLMLocalSamplingParameters = .init()
    ) {
        self.modelPath = modelPath
        self.parameters = parameters
        self.contextParameters = contextParameters
        self.samplingParameters = samplingParameters
        Task { @MainActor in
            self.context.append(systemMessage: parameters.systemPrompt)
        }
    }
    
    
    public func setup(runnerConfig: LLMRunnerConfiguration) async throws {
        Self.logger.debug("SpeziLLMLocal: Local LLM is being initialized")
        await MainActor.run {
            self.state = .loading
        }
        
        guard let model = llama_load_model_from_file(modelPath.path().cString(using: .utf8), parameters.llamaCppRepresentation) else {
            Self.logger.error("SpeziLLMLocal: Local LLM file could not be opened, indicating that the model file doesn't exist")
            await MainActor.run {
                self.state = .error(error: LLMLocalError.modelNotFound)
            }
            throw LLMLocalError.modelNotFound
        }
        
        /// Check if model was trained for the configured context window size
        guard self.contextParameters.contextWindowSize <= llama_n_ctx_train(model) else {
            Self.logger.error("SpeziLLMLocal: Model was trained on only \(llama_n_ctx_train(model), privacy: .public) context tokens, not the configured \(self.contextParameters.contextWindowSize, privacy: .public) context tokens")
            await MainActor.run {
                self.state = .error(error: LLMLocalError.contextSizeMismatch)
            }
            throw LLMLocalError.contextSizeMismatch
        }
        
        self.model = model
        
        await MainActor.run {
            self.state = .ready
        }
        Self.logger.debug("SpeziLLMLocal: Local LLM finished initializing, now ready to use")
    }
    
    public func generate(continuation: AsyncThrowingStream<String, Error>.Continuation) async {
        Self.logger.debug("SpeziLLMLocal: Local LLM started a new inference")
        await _generate(continuation: continuation)
        Self.logger.debug("SpeziLLMLocal: Local LLM completed an inference")
    }
    
    
    /// Upon deinit, free the context and the model via llama.cpp
    deinit {
        llama_free(self.modelContext)
        llama_free_model(self.model)
    }
}
