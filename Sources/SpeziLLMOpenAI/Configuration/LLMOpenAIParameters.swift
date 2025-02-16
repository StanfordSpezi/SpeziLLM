//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import OpenAPIRuntime


/// Represents the parameters of OpenAIs LLMs.
public struct LLMOpenAIParameters: Sendable {
    public enum ModelType: String, Sendable {
        // swiftlint:disable identifier_name

        // GPT-4 series
        case gpt4o = "gpt-4o"
        case gpt4o_mini = "gpt-4o-mini"
        case gpt4_turbo = "gpt-4-turbo"

        // o-series
        case o3_mini = "o3-mini"
        case o3_mini_high = "o3-mini-high"
        case o1 = "o1"
        case o1_mini = "o1-mini"

        // Others
        case gpt3_5_turbo = "gpt-3.5-turbo"

        // swiftlint:enable identifier_name
    }

    /// Defaults of possible LLMs parameter settings.
    public enum Defaults {
        public static let defaultOpenAISystemPrompt: String = {
            String(localized: LocalizedStringResource("SPEZI_LLM_OPENAI_SYSTEM_PROMPT", bundle: .atURL(from: .module)))
        }()
    }
    
    
    /// The to-be-used OpenAI model.
    let modelType: String
    /// The to-be-used system prompt(s) of the LLM.
    let systemPrompts: [String]
    /// Indicates if a model access test should be made during LLM setup.
    let modelAccessTest: Bool
    /// Separate OpenAI token that overrides the one defined within the ``LLMOpenAIPlatform``.
    let overwritingToken: String?
    
    
    /// Creates the ``LLMOpenAIParameters``.
    ///
    /// - Parameters:
    ///   - modelType: The to-be-used OpenAI model such as GPT3.5 or GPT4.
    ///   - systemPrompt: The to-be-used system prompt of the LLM enabling fine-tuning of the LLMs behaviour. Defaults to the regular OpenAI chat-based GPT system prompt.
    ///   - modelAccessTest: Indicates if access to the configured OpenAI model via the specified token should be made upon LLM setup.
    ///   - overwritingToken: Separate OpenAI token that overrides the one defined within the ``LLMOpenAIPlatform``.
    public init(
        modelType: ModelType,
        systemPrompt: String? = Defaults.defaultOpenAISystemPrompt,
        modelAccessTest: Bool = false,
        overwritingToken: String? = nil
    ) {
        self.init(
            modelType: modelType.rawValue,
            systemPrompts: systemPrompt.map { [$0] } ?? [],
            modelAccessTest: modelAccessTest,
            overwritingToken: overwritingToken
        )
    }
    
    /// Creates the ``LLMOpenAIParameters``.
    ///
    /// - Parameters:
    ///   - modelType: The to-be-used OpenAI model such as GPT3.5 or GPT4.
    ///   - systemPrompts: The to-be-used system prompt(s) of the LLM enabling fine-tuning of the LLMs behaviour. Defaults to the regular OpenAI chat-based GPT system prompt.
    ///   - modelAccessTest: Indicates if access to the configured OpenAI model via the specified token should be made upon LLM setup.
    ///   - overwritingToken: Separate OpenAI token that overrides the one defined within the ``LLMOpenAIPlatform``.
    @_disfavoredOverload
    public init(
        modelType: String,
        systemPrompts: [String] = [Defaults.defaultOpenAISystemPrompt],
        modelAccessTest: Bool = false,
        overwritingToken: String? = nil
    ) {
        self.modelType = modelType
        self.systemPrompts = systemPrompts
        self.modelAccessTest = modelAccessTest
        self.overwritingToken = overwritingToken
    }
}
