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


/// Represents the parameters of OpenAIs LLMs.
public struct LLMOpenAIParameters: Sendable {
    public struct ModelType: Hashable, RawRepresentable, Codable, Sendable {
        /// The identifier of the underlying model.
        public let rawValue: String
        
        /// Creates a new `ModelType`
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
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
    let overwritingAuthToken: RemoteLLMInferenceAuthToken?

    
    /// Creates the ``LLMOpenAIParameters``.
    ///
    /// - Parameters:
    ///   - modelType: The to-be-used OpenAI model such as GPT3.5 or GPT4.
    ///   - systemPrompt: The to-be-used system prompt of the LLM enabling fine-tuning of the LLMs behaviour. Defaults to the regular OpenAI chat-based GPT system prompt.
    ///   - modelAccessTest: Indicates if access to the configured OpenAI model via the specified token should be made upon LLM setup.
    ///   - overwritingAuthToken: Separate OpenAI token that overrides the one defined within the ``LLMOpenAIPlatform``.
    public init(
        modelType: ModelType,
        systemPrompt: String? = Defaults.defaultOpenAISystemPrompt,
        modelAccessTest: Bool = false,
        overwritingAuthToken: RemoteLLMInferenceAuthToken? = nil
    ) {
        self.init(
            modelType: modelType.rawValue,
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
    @_disfavoredOverload
    public init(
        modelType: String,
        systemPrompts: [String] = [Defaults.defaultOpenAISystemPrompt],
        modelAccessTest: Bool = false,
        overwritingAuthToken: RemoteLLMInferenceAuthToken? = nil
    ) {
        self.modelType = modelType
        self.systemPrompts = systemPrompts
        self.modelAccessTest = modelAccessTest
        self.overwritingAuthToken = overwritingAuthToken
    }
}


// swiftlint:disable identifier_name missing_docs
extension LLMOpenAIParameters.ModelType {
    // GPT-5 series
    public static let gpt5 = Self(rawValue: "gpt-5")
    public static let gpt5_mini = Self(rawValue: "gpt-5-mini")
    public static let gpt5_nano = Self(rawValue: "gpt-5-nano")
    public static let gpt5_chat = Self(rawValue: "gpt-5-chat-latest")

    // GPT-4 series
    public static let gpt4o = Self(rawValue: "gpt-4o")
    public static let gpt4o_mini = Self(rawValue: "gpt-4o-mini")
    public static let gpt4_turbo = Self(rawValue: "gpt-4-turbo")
    public static let gpt4_1 = Self(rawValue: "gpt-4.1")
    public static let gpt4_1_mini = Self(rawValue: "gpt-4.1-mini")
    public static let gpt4_1_nano = Self(rawValue: "gpt-4.1-nano")

    // o-series
    public static let o4_mini = Self(rawValue: "o4-mini")
    public static let o3 = Self(rawValue: "o3")
    public static let o3_pro = Self(rawValue: "o3-pro")
    public static let o3_mini = Self(rawValue: "o3-mini")
    public static let o3_mini_high = Self(rawValue: "o3-mini-high")
    public static let o1_pro = Self(rawValue: "o1-pro")
    public static let o1 = Self(rawValue: "o1")
    public static let o1_mini = Self(rawValue: "o1-mini")

    // Others
    public static let gpt3_5_turbo = Self(rawValue: "gpt-3.5-turbo")
}
