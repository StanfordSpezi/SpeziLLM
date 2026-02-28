//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import GeneratedOpenAIClient
import OpenAPIRuntime


/// Represents the parameters of OpenAI-like LLMs.
public struct LLMOpenAIParameters<PlatformDefinition: LLMOpenAILikePlatformDefinition>: Sendable {
    /// The to-be-used OpenAI model.
    let modelType: PlatformDefinition.ModelType
    /// The to-be-used system prompt(s) of the LLM.
    let systemPrompts: [String]
    /// Indicates if a model access test should be made during LLM setup.
    let modelAccessTest: Bool
    /// Separate OpenAI token that overrides the one defined within the ``LLMOpenAIPlatform``.
    let overwritingAuthToken: RemoteLLMInferenceAuthToken?
    
    
    /// Creates the ``LLMOpenAIParameters``.
    ///
    /// - Parameters:
    ///   - modelType: The to-be-used OpenAI model such as GPT3.5 or GPT4.
    ///   - systemPrompt: The to-be-used system prompt of the LLM enabling fine-tuning of the LLMs behaviour. Defaults to the regular OpenAI chat-based GPT system prompt.
    ///   - modelAccessTest: Indicates if access to the configured OpenAI model via the specified token should be made upon LLM setup.
    ///   - overwritingAuthToken: Separate OpenAI token that overrides the one defined within the ``LLMOpenAIPlatform``.
    public init(
        modelType: PlatformDefinition.ModelType,
        systemPrompt: String? = nil,
        modelAccessTest: Bool = false,
        overwritingAuthToken: RemoteLLMInferenceAuthToken? = nil
    ) {
        self.init(
            modelType: modelType,
            systemPrompts: systemPrompt.map { [$0] } ?? [],
            modelAccessTest: modelAccessTest,
            overwritingAuthToken: overwritingAuthToken
        )
    }
    
    /// Creates the ``LLMOpenAIParameters``.
    ///
    /// - Parameters:
    ///   - modelType: The to-be-used OpenAI model such as GPT3.5 or GPT4.
    ///   - systemPrompts: The to-be-used system prompt(s) of the LLM enabling fine-tuning of the LLMs behaviour. Defaults to the regular OpenAI chat-based GPT system prompt.
    ///   - modelAccessTest: Indicates if access to the configured OpenAI model via the specified token should be made upon LLM setup.
    ///   - overwritingAuthToken: Separate OpenAI token that overrides the one defined within the ``LLMOpenAIPlatform``.
    public init(
        modelType: PlatformDefinition.ModelType,
        systemPrompts: [String],
        modelAccessTest: Bool = false,
        overwritingAuthToken: RemoteLLMInferenceAuthToken? = nil
    ) {
        self.modelType = modelType
        self.systemPrompts = systemPrompts
        self.modelAccessTest = modelAccessTest
        self.overwritingAuthToken = overwritingAuthToken
    }
}
