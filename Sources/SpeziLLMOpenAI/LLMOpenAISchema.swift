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


/// Defines the type and configuration of the ``LLMOpenAISession``.
///
/// The ``LLMOpenAISchema`` is used as a configuration for the to-be-used OpenAI LLM. It contains all information necessary for the creation of an executable ``LLMOpenAISession``.
/// It is bound to a ``LLMOpenAIPlatform`` that is responsible for turning the ``LLMOpenAISchema`` to an ``LLMOpenAISession``.
///
/// - Tip: ``LLMOpenAISchema`` also enables the function calling mechanism to establish a structured, bidirectional, and reliable communication between the OpenAI LLMs and external tools. For details, refer to ``LLMFunction`` and ``LLMFunction/Parameter`` or the <doc:FunctionCalling> DocC article.
///
/// - Tip: For more information, refer to the documentation of the `LLMSchema` from SpeziLLM.
public struct LLMOpenAISchema: LLMSchema, Sendable {
    public typealias Platform = LLMOpenAIPlatform
    
    
    /// Default values of ``LLMOpenAISchema``.
    public enum Defaults {
        /// Empty default of passed function calls (`_LLMFunctionCollection`).
        /// Reason: Cannot use internal init of `_LLMFunctionCollection` as default parameter within public ``LLMOpenAISchema/init(parameters:modelParameters:injectIntoContext:_:)``.
        nonisolated(unsafe) public static let emptyLLMFunctions: _LLMFunctionCollection = .init(functions: [])
    }
    
    
    let parameters: LLMOpenAIParameters
    let modelParameters: LLMOpenAIModelParameters
    let functions: [String: any LLMFunction]
    public let injectIntoContext: Bool
    
    
    /// Creates an instance of the ``LLMOpenAISchema`` containing all necessary configuration for OpenAI LLM inference.
    ///
    /// - Parameters:
    ///    - parameters: Parameters of the OpenAI LLM client.
    ///    - modelParameters: Parameters of the used OpenAI LLM.
    ///    - injectIntoContext: Indicates if the inference output by the ``LLMOpenAISession`` should automatically be inserted into the ``LLMOpenAISession/context``, defaults to false.
    ///    - functionsCollection: LLM Functions (tools) used for the OpenAI function calling mechanism.
    public init(
        parameters: LLMOpenAIParameters,
        modelParameters: LLMOpenAIModelParameters = .init(),
        injectIntoContext: Bool = false,
        @LLMFunctionBuilder _ functionsCollection: () -> _LLMFunctionCollection = { Defaults.emptyLLMFunctions }
    ) {
        self.parameters = parameters
        self.modelParameters = modelParameters
        self.injectIntoContext = injectIntoContext
        self.functions = functionsCollection().functions
    }
}
