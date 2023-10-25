//
// This source file is part of the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
import llama


public actor SpeziLLMModelLlama: SpeziLLMModel {
    private let modelPath: URL
    let modelParameters: SpeziModelParams
    let contextParameters: SpeziContextParams
    
    public let type: SpeziLLMModelType = .local
    public var state: SpeziLLMState = .uninitialized
    var model: OpaquePointer?
    
    
    public init(
        modelPath: URL,
        modelParameters: SpeziModelParams = .init(),
        contextParameters: SpeziContextParams = .init()
    ) {
        self.modelPath = modelPath
        self.modelParameters = modelParameters
        self.contextParameters = contextParameters
    }
    
    
    public func setup(runnerConfig: SpeziLLMRunnerConfig) async throws {
        self.state = .loading
        
        guard let model = llama_load_model_from_file(modelPath.path().cString(using: .utf8), modelParameters.wrapped) else {
            throw SpeziLLMError.modelNotFound
        }
        self.model = model
        
        self.state = .ready
    }
    
    public func generate(prompt: String, continuation: AsyncThrowingStream<String, Error>.Continuation) async {
        _generate(prompt: prompt, continuation: continuation)
    }
    
    
    deinit {
        llama_free_model(self.model)
    }
}
