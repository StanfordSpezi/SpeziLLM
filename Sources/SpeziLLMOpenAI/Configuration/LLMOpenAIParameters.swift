//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import OpenAI


/// Represents the parameters of OpenAIs LLMs.
public struct LLMOpenAIParameters: Sendable {
    /// Defaults of possible LLMs parameter settings.
    public enum Defaults {
        public static let defaultOpenAISystemPrompt: String = {
            String(localized: LocalizedStringResource("SPEZI_LLM_OPENAI_SYSTEM_PROMPT", bundle: .atURL(from: .module)))
        }()
    }
    
    /// The to-be-used OpenAI model.
    let modelType: Model
    /// The to-be-used system prompt of the LLM.
    let systemPrompt: String
    /// Separate OpenAI token that overrides the one defined within the ``LLMRemoteRunnerSetupTask``.
    let overwritingToken: String?
    
    
    /// Creates the ``LLMOpenAIParameters``.
    ///
    /// - Parameters:
    ///   - modelType: The to-be-used OpenAI model such as GPT3.5 or GPT4.
    ///   - systemPrompt: The to-be-used system prompt of the LLM enabling fine-tuning of the LLMs behaviour. Defaults to the regular OpenAI chat-based GPT system prompt.
    ///   - overwritingToken: Separate OpenAI token that overrides the one defined within the ``LLMOpenAIRunnerSetupTask``.
    public init(
        modelType: Model,
        systemPrompt: String = Defaults.defaultOpenAISystemPrompt,
        overwritingToken: String? = nil
    ) {
        self.modelType = modelType
        self.systemPrompt = systemPrompt
        self.overwritingToken = overwritingToken
    }
}
