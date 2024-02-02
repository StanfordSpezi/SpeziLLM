//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziChat
import SpeziLLM


public struct LLMOpenAISchema: LLMSchema {
    public typealias Platform = LLMOpenAIPlatform
    
    
    /// Default values of ``LLMOpenAI``.
    public enum Defaults {
        /// Empty default of passed function calls (`_LLMFunctionCollection`).
        /// Reason: Cannot use internal init of `_LLMFunctionCollection` as default parameter within public ``LLMOpenAI/init(parameters:modelParameters:_:)``.
        public static let emptyLLMFunctions: _LLMFunctionCollection = .init(functions: [])
    }
    
    
    let parameters: LLMOpenAIParameters
    let modelParameters: LLMOpenAIModelParameters
    public let injectIntoContext: Bool
    let functions: [String: LLMFunction]
    
    
    public init(
        parameters: LLMOpenAIParameters,
        modelParameters: LLMOpenAIModelParameters = .init(),
        injectIntoContext: Bool = false,
        @LLMFunctionBuilder _ functionsCollection: @escaping () -> _LLMFunctionCollection = { Defaults.emptyLLMFunctions }
    ) {
        self.parameters = parameters
        self.modelParameters = modelParameters
        self.injectIntoContext = injectIntoContext
        self.functions = functionsCollection().functions
    }
}
