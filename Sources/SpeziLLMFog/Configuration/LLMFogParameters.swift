//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziLLM


/// Represents the parameters of Fog LLMs.
public struct LLMFogParameters: Sendable {
    // todo: what to do with that? has been the type of the modelType parameter in the init
    public enum FogModel: String, Sendable {
        /// The Gemma model from Google DeepMind in its 7B variation.
        case gemma7B = "gemma"
        /// The Gemma model from Google DeepMind in its 2B variation.
        case gemma2B = "gemma:2b"
        /// The Llama 2 model from Meta in its 7B variation.
        case llama7B = "llama2"
        /// The Llama 2 model from Meta in its 13B variation.
        case llama13B = "llama2:13b"
        /// The Llama 2 model from Meta in its 70B variation.
        case llama70B = "llama2:70b"
        /// The 7B model released by Mistral AI, updated to version 0.2.
        case mistral
        /// A high-quality Mixture of Experts (MoE) model with open weights by Mistral AI.
        case mixtral
        /// 2.7B language model by Microsoft Research that demonstrates outstanding reasoning and language understanding capabilities.
        case phi
        /// The TinyLlama project is an open endeavour to train a compact 1.1B Llama model on 3 trillion tokens.
        case tinyllama
    }
    
    
    /// The to-be-used Fog LLM model.
    let modelType: LLMFogRequestType.modelPayload
    /// The to-be-used system prompt(s) of the LLM.
    let systemPrompts: [String]
    /// Closure that returns an up-to-date auth token for requests to Fog LLMs (e.g., a Firebase ID token).
    let authToken: @Sendable () async -> String?
    
    
    /// Creates the ``LLMFogParameters``.
    ///
    /// - Parameters:
    ///   - modelType: The to-be-used Fog LLM model such as Google's Gemma models or Meta Llama models.
    ///   - systemPrompt: The to-be-used system prompt of the LLM enabling fine-tuning of the LLMs behaviour. Defaults to the regular Llama2 system prompt.
    ///   - authToken: Closure that returns an up-to-date auth token for requests to Fog LLMs (e.g., a Firebase ID token).
    public init(
        modelType: LLMFogRequestType.modelPayload,
        systemPrompt: String? = nil,
        authToken: @Sendable @escaping () async -> String?
    ) {
        self.init(modelType: modelType, systemPrompts: systemPrompt.map { [$0] } ?? [], authToken: authToken)
    }
    
    /// Creates the ``LLMFogParameters``.
    ///
    /// - Parameters:
    ///   - modelType: The to-be-used Fog LLM model such as Google's Gemma models or Meta Llama models.
    ///   - systemPrompts: The to-be-used system prompt of the LLM enabling fine-tuning of the LLMs behaviour. Defaults to the regular Llama2 system prompt.
    ///   - authToken: Closure that returns an up-to-date auth token for requests to Fog LLMs (e.g., a Firebase ID token).
    @_disfavoredOverload
    public init(
        modelType: LLMFogRequestType.modelPayload,
        systemPrompts: [String] = [],
        authToken: @Sendable @escaping () async -> String?
    ) {
        self.modelType = modelType
        self.systemPrompts = systemPrompts
        self.authToken = authToken
    }
}
