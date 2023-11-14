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
/// - Note: ``LLMLlama`` shouldn't be used on it's own but always wrapped by the Spezi `LLMRunner` as the runner handles
/// all management overhead tasks. A code example on how to use ``LLMLlama`` in combination with the `LLMRunner` can be
/// found in the documentation of the `LLMRunner`.
public actor LLMLlama: LLM {
    /// A Swift Logger that logs important information from the ``LLMLlama``.
    static let logger = Logger(subsystem: "edu.stanford.spezi", category: "SpeziML")
    public let type: LLMHostingType = .local
    public var state: LLMState = .uninitialized
    
    /// Parameters of the llama.cpp ``LLM``.
    let parameters: LLMParameters
    /// Context parameters of the llama.cpp ``LLM``.
    let contextParameters: LLMContextParameters
    /// The on-device `URL` where the model is located.
    private let modelPath: URL
    /// A pointer to the allocated model via llama.cpp.
    var model: OpaquePointer?
    
    
    /// Creates a ``LLMLlama`` instance that can then be passed to the `LLMRunner` for execution.
    ///
    /// - Parameters:
    ///   - modelPath: A local `URL` where the LLM file is stored. The format of the LLM must be in the llama.cpp `.gguf` format.
    ///   - parameters: Parameterize the ``LLMLlama`` via ``LLMParameters``.
    ///   - contextParameters: Configure the context of the ``LLMLlama`` via ``LLMContextParameters``.
    public init(
        modelPath: URL,
        parameters: LLMParameters = .init(),
        contextParameters: LLMContextParameters = .init()
    ) {
        self.modelPath = modelPath
        self.parameters = parameters
        self.contextParameters = contextParameters
    }
    
    
    public func setup(runnerConfig: LLMRunnerConfiguration) async throws {
        self.state = .loading
        
        guard let model = llama_load_model_from_file(modelPath.path().cString(using: .utf8), parameters.getLlamaCppRepresentation()) else {
            throw LLMError.modelNotFound
        }
        self.model = model
        
        self.state = .ready
    }
    
    public func generate(prompt: String, continuation: AsyncThrowingStream<String, Error>.Continuation) async {
        _generate(prompt: prompt, continuation: continuation)
    }
    
    
    /// Upon deinit, free the model via llama.cpp
    deinit {
        llama_free_model(self.model)
    }
}
