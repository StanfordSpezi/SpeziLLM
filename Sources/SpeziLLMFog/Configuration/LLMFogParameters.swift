//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import GeneratedOpenAIClient
import SpeziLLM


/// Represents the parameters of Fog LLMs.
public struct LLMFogParameters: Sendable {
    public enum FogModelType: String, Sendable {
        // swiftlint:disable identifier_name

        // DeepSeek

        /// The DeepSeek R1 reasoning model in its 7B variant.
        case deepSeekR1 = "deepseek-r1"
        /// The DeepSeek R1 reasoning model in its 1.5B variant.
        case deepSeekR1_1_5B = "deepseek-r1:1.5b"
        /// The DeepSeek R1 reasoning model in its 8B variant.
        case deepSeekR1_8B = "deepseek-r1:8b"
        /// The DeepSeek R1 reasoning model in its 14B variant.
        case deepSeekR1_14B = "deepseek-r1:14b"
        /// The DeepSeek R1 reasoning model in its 32B variant.
        case deepSeekR1_32B = "deepseek-r1:32b"
        /// The DeepSeek R1 reasoning model in its 70B variant.
        case deepSeekR1_70B = "deepseek-r1:70b"
        /// The DeepSeek R1 reasoning model in its 671B variant.
        case deepSeekR1_671B = "deepseek-r1:671b"

        // Llama

        /// The  Llama 3.3 model in its 70B variant.
        case llama3_3 = "llama3.3"
        /// The  Llama 3.2 model in its 3B variant.
        case llama3_2 = "llama3.2"
        /// The  Llama 3.2 model in its 1B variant.
        case llama3_2_1B = "llama3.2:1b"
        /// The  Llama 3.1 model in its 8B variant.
        case llama3_1_8B = "llama3.1:8b"
        /// The  Llama 3.1 model in its 70B variant.
        case llama3_1_70B = "llama3.1:70b"
        /// The  Llama 3.1 model in its 405B variant.
        case llama3_1_405B = "llama3.1:405b"

        /// The Llama 2 model from Meta in its 7B variation.
        case llama2_7B = "llama2"
        /// The Llama 2 model from Meta in its 13B variation.
        case llama2_13B = "llama2:13b"
        /// The Llama 2 model from Meta in its 70B variation.
        case llama2_70B = "llama2:70b"

        /// The TinyLlama project is an open endeavour to train a compact 1.1B Llama model on 3 trillion tokens.
        case tinyllama

        // Phi

        /// The Phi-4 model in its 14B variant.
        case phi4 = "phi4"

        // Gemma

        /// The Gemma model from Google DeepMind in its 7B variation.
        case gemma_7B = "gemma"
        /// The Gemma model from Google DeepMind in its 2B variation.
        case gemma_2B = "gemma:2b"

        // Others

        /// The 7B model released by Mistral AI, updated to version 0.3.
        case mistral
        /// A high-quality Mixture of Experts (MoE) model with open weights by Mistral AI.
        case mixtral

        // swiftlint:enable identifier_name
    }
    
    
    /// The to-be-used Fog LLM model.
    let modelType: String
    /// Token to authenticate with the fog node (such as a Firebase Token). Overwrites the token defined on the ``LLMFogPlatform``.
    let overwritingAuthToken: RemoteLLMInferenceAuthToken?
    /// The to-be-used system prompt(s) of the LLM.
    let systemPrompts: [String]

    
    /// Creates the ``LLMFogParameters``.
    ///
    /// - Parameters:
    ///   - modelType: The to-be-used Fog LLM model such as Meta's Llama models.
    ///   - overwritingAuthToken: Token to authenticate with the fog node (such as a Firebase Token), defaults to `nil`. Overwrites the token defined on the ``LLMFogPlatform``.
    ///   - systemPrompt: The to-be-used system prompt of the LLM enabling fine-tuning of the LLMs behaviour. Defaults to the regular Llama2 system prompt.
    public init(
        modelType: FogModelType,
        overwritingAuthToken: RemoteLLMInferenceAuthToken? = nil,
        systemPrompt: String? = nil
    ) {
        self.init(modelType: modelType.rawValue, overwritingAuthToken: overwritingAuthToken, systemPrompts: systemPrompt.map { [$0] } ?? [])
    }
    
    /// Creates the ``LLMFogParameters``.
    ///
    /// - Parameters:
    ///   - modelType: The to-be-used Fog LLM model such as Meta's Llama models.
    ///   - overwritingAuthToken: Token to authenticate with the fog node (such as a Firebase Token), defaults to `nil`. Overwrites the token defined on the ``LLMFogPlatform``.
    ///   - systemPrompts: The to-be-used system prompt of the LLM enabling fine-tuning of the LLMs behaviour. Defaults to the regular Llama2 system prompt.
    @_disfavoredOverload
    public init(
        modelType: String,
        overwritingAuthToken: RemoteLLMInferenceAuthToken? = nil,
        systemPrompts: [String] = []
    ) {
        self.modelType = modelType
        self.overwritingAuthToken = overwritingAuthToken
        self.systemPrompts = systemPrompts
    }
}
