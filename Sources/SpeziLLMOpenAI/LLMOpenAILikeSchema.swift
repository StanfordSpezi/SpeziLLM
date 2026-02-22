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
public struct LLMOpenAILikeSchema<PlatformDefinition: LLMOpenAILikePlatformDefinition>: LLMSchema, Sendable {
    public typealias Platform = LLMOpenAILikePlatform<PlatformDefinition>
    
    let parameters: LLMOpenAIParameters<PlatformDefinition>
    let modelParameters: LLMOpenAIModelParameters
    let functions: [String: any LLMFunction]
    public let injectIntoContext: Bool
    
    
    /// Creates an instance of the ``LLMOpenAISchema`` containing all necessary configuration for OpenAI LLM inference.
    ///
    /// - Parameters:
    ///    - parameters: Parameters of the OpenAI LLM client.
    ///    - modelParameters: Parameters of the used OpenAI LLM.
    ///    - injectIntoContext: Indicates if the inference output by the ``LLMOpenAISession`` should automatically be inserted into the ``LLMOpenAILikeSession/context``, defaults to false.
    ///    - functions: LLM Functions (tools) used for the OpenAI function calling mechanism.
    public init(
        parameters: LLMOpenAIParameters<PlatformDefinition>,
        modelParameters: LLMOpenAIModelParameters = .init(),
        injectIntoContext: Bool = false,
        @LLMFunctionBuilder _ functions: () -> _LLMFunctionCollection = { _LLMFunctionCollection() }
    ) {
        self.parameters = parameters
        self.modelParameters = modelParameters
        self.injectIntoContext = injectIntoContext
        self.functions = functions().functions
    }
}
