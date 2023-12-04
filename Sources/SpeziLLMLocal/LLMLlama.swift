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
import SpeziLLM


/// The ``LLMLlama`` is a Spezi `LLM` and utilizes the llama.cpp library to locally execute an LLM on-device.
/// 
/// - Important: ``LLMLlama`` shouldn't be used on it's own but always wrapped by the Spezi `LLMRunner` as the runner handles
/// all management overhead tasks. A code example on how to use ``LLMLlama`` in combination with the `LLMRunner` can be
/// found in the documentation of the `LLMRunner`.
public actor LLMLlama: LLM {
    /// A Swift Logger that logs important information from the ``LLMLlama``.
    static let logger = Logger(subsystem: "edu.stanford.spezi", category: "SpeziLLM")
    public let type: LLMHostingType = .local
    @MainActor public var state: LLMState = .uninitialized
    
    /// Parameters of the llama.cpp ``LLM``.
    let parameters: LLMParameters
    /// Context parameters of the llama.cpp ``LLM``.
    let contextParameters: LLMContextParameters
    /// Sampling parameters of the llama.cpp ``LLM``.
    let samplingParameters: LLMSamplingParameters
    /// The on-device `URL` where the model is located.
    private let modelPath: URL
    /// A pointer to the allocated model via llama.cpp.
    var model: OpaquePointer?
    /// A pointer to the allocated model context from llama.cpp.
    var context: OpaquePointer?
    /// Keeps track of all already text being processed by the LLM, including the system prompt, instructions, and model responses.
    var generatedText: String = ""
    
    
    /// Creates a ``LLMLlama`` instance that can then be passed to the `LLMRunner` for execution.
    ///
    /// - Parameters:
    ///   - modelPath: A local `URL` where the LLM file is stored. The format of the LLM must be in the llama.cpp `.gguf` format.
    ///   - parameters: Parameterize the ``LLMLlama`` via ``LLMParameters``.
    ///   - contextParameters: Configure the context of the ``LLMLlama`` via ``LLMContextParameters``.
    ///   - samplingParameters: Parameterize the sampling methods of the ``LLMLlama`` via ``LLMSamplingParameters``.
    public init(
        modelPath: URL,
        parameters: LLMParameters = .init(),
        contextParameters: LLMContextParameters = .init(),
        samplingParameters: LLMSamplingParameters = .init()
    ) {
        self.modelPath = modelPath
        self.parameters = parameters
        self.contextParameters = contextParameters
        self.samplingParameters = samplingParameters
    }
    
    
    public func setup(runnerConfig: LLMRunnerConfiguration) async throws {
        await MainActor.run {
            self.state = .loading
        }
        
        guard let model = llama_load_model_from_file(modelPath.path().cString(using: .utf8), parameters.llamaCppRepresentation) else {
            await MainActor.run {
                self.state = .error(error: LLMError.modelNotFound)
            }
            throw LLMError.modelNotFound
        }
        
        /// Check if model was trained for the configured context window size
        guard self.contextParameters.contextWindowSize <= llama_n_ctx_train(model) else {
            Self.logger.warning("Model was trained on only \(llama_n_ctx_train(model), privacy: .public) context tokens, not the configured \(self.contextParameters.contextWindowSize, privacy: .public) context tokens")
            await MainActor.run {
                self.state = .error(error: LLMError.generationError)
            }
            throw LLMError.modelNotFound
        }
        
        self.model = model
        
        await MainActor.run {
            self.state = .ready
        }
    }
    
    public func generate(prompt: String, continuation: AsyncThrowingStream<String, Error>.Continuation) async {
        await _generate(prompt: prompt, continuation: continuation)
    }
    
    
    /// Upon deinit, free the context and the model via llama.cpp
    deinit {
        llama_free(context)
        llama_free_model(self.model)
    }
}
