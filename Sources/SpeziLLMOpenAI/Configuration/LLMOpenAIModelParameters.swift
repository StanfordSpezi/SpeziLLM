//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import OpenAPIRuntime

/// Represents the model-specific parameters of OpenAIs LLMs.
public struct LLMOpenAIModelParameters: Sendable {
    /// The format for model responses.
    let responseFormat: Components.Schemas.CreateChatCompletionRequest.response_formatPayload?
    /// The sampling temperature (0 to 2). Higher values increase randomness, lower values enhance focus.
    let temperature: Double?
    /// Nucleus sampling threshold. Considers tokens with top_p probability mass. Alternative to temperature sampling.
    let topP: Double?
    /// The number of generated chat completions per input.
    let completionsPerOutput: Int?
    /// Sequences (up to 4) where generation stops. Output doesn't include these sequences.
    let stopSequence: [String]
    /// Maximum token count for each completion.
    let maxOutputLength: Int?
    /// OpenAI will make a best effort to sample deterministically, such that repeated requests with the same seed and parameters should return the same result. Determinism is not guaranteed.
    let seed: Int?
    /// Adjusts new topic exploration (-2.0 to 2.0). Higher values encourage novelty.
    let presencePenalty: Double?
    /// Controls repetition (-2.0 to 2.0). Higher values reduce the likelihood of repeating content.
    let frequencyPenalty: Double?
    /// Alters specific token's likelihood in completion.
    let logitBias: Components.Schemas.CreateChatCompletionRequest.logit_biasPayload
    /// Unique identifier for the end-user, aiding in abuse monitoring.
    let user: String?
    
    
    /// Initializes ``LLMOpenAIModelParameters`` for OpenAI model configuration.
    ///
    /// - Parameters:
    ///   - responseFormat: Format for model responses.
    ///   - temperature: Sampling temperature (0 to 2); higher values (e.g., 0.8) increase randomness, lower values (e.g., 0.2) enhance focus. Adjust this or topP, not both.
    ///   - topP: Nucleus sampling threshold; considers tokens with top_p probability mass. Alternative to temperature sampling.
    ///   - completionsPerOutput: Number of generated chat completions (choices) per input, defaults to 1 choice.
    ///   - stopSequence: Sequences (up to 4) where generation stops; output doesn't include these sequences.
    ///   - maxOutputLength: Maximum token count for each completion.
    ///   - seed: OpenAI will make a best effort to sample deterministically, such that repeated requests with the same seed and parameters should return the same result. Determinism is not guaranteed.
    ///   - presencePenalty: Adjusts new topic exploration (-2.0 to 2.0); higher values encourage novelty.
    ///   - frequencyPenalty: Controls repetition (-2.0 to 2.0); higher values reduce likelihood of repeating content.
    ///   - logitBias: Alters specific token's likelihood in completion.
    ///   - user: Unique identifier for the end-user, aiding in abuse monitoring.
    public init(
        responseFormat: Components.Schemas.CreateChatCompletionRequest.response_formatPayload? = nil,
        temperature: Double? = nil,
        topP: Double? = nil,
        completionsPerOutput: Int? = nil,
        stopSequence: [String] = [],
        maxOutputLength: Int? = nil,
        seed: Int? = nil,
        presencePenalty: Double? = nil,
        frequencyPenalty: Double? = nil,
        logitBias: [String: Int] = [:],
        user: String? = nil
    ) {
        self.responseFormat = responseFormat
        self.temperature = temperature
        self.topP = topP
        self.completionsPerOutput = completionsPerOutput
        self.stopSequence = stopSequence
        self.maxOutputLength = maxOutputLength
        self.seed = seed
        self.presencePenalty = presencePenalty
        self.frequencyPenalty = frequencyPenalty
        self.logitBias = Components.Schemas.CreateChatCompletionRequest
            .logit_biasPayload(additionalProperties: logitBias)
        self.user = user
    }
}
