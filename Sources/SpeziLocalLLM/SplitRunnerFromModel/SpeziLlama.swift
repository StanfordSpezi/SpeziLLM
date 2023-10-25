//
// This source file is part of the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
import llama
import Spezi


public actor SpeziLlama: Component, ObservableObject, ObservableObjectProvider {
    @Dependency private var runner: SpeziLocalLLMRunner
    
    private let modelPath: URL
    let modelParameters: SpeziModelParams
    let contextParameters: SpeziContextParams
    var model: OpaquePointer?
    
    
    var state: SpeziLLMModelState {
        runner.state
    }
    
    
    public init(
        modelPath: URL,
        modelParameters: SpeziModelParams = .init(),
        contextParameters: SpeziContextParams = .init()
    ) {
        self.modelPath = modelPath
        self.modelParameters = modelParameters
        self.contextParameters = contextParameters
    }
    
    
    nonisolated public func configure() {
        /*
        guard let model = llama_load_model_from_file(modelPath.path().cString(using: .utf8), modelParameters.wrapped) else {
            print("Failed to load model")
            Task { @MainActor in
                self.state = .error(error: .modelNotFound)
            }
            
            throw SpeziLLMError.modelNotFound
        }
        self.model = model
         */
    }
}
