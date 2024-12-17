//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import OpenAI


/// Represents the model-specific parameters of Fog LLMs.
public struct LLMFogModelParameters: Sendable {
    /// The format for model responses.
    let responseFormat: ChatQuery.ResponseFormat?
    /// The sampling temperature (0 to 2). Higher values increase randomness, lower values enhance focus.
    let temperature: Double?
    /// Nucleus sampling threshold. Considers tokens with top_p probability mass. Alternative to temperature sampling.
    let topP: Double?
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
    
    
    /// Initializes ``LLMFogModelParameters`` for Fog LLM model configuration.
    ///
    /// - Parameters:
    ///   - responseFormat: Format for model responses.
    ///   - temperature: Sampling temperature (0 to 2); higher values (e.g., 0.8) increase randomness, lower values (e.g., 0.2) enhance focus. Adjust this or topP, not both.
    ///   - topP: Nucleus sampling threshold; considers tokens with top_p probability mass. Alternative to temperature sampling.
    ///   - stopSequence: Sequences (up to 4) where generation stops; output doesn't include these sequences.
    ///   - maxOutputLength: Maximum token count for each completion.
    ///   - seed: OpenAI will make a best effort to sample deterministically, such that repeated requests with the same seed and parameters should return the same result. Determinism is not guaranteed.
    ///   - presencePenalty: Adjusts new topic exploration (-2.0 to 2.0); higher values encourage novelty.
    ///   - frequencyPenalty: Controls repetition (-2.0 to 2.0); higher values reduce likelihood of repeating content.
    public init(
        responseFormat: ChatQuery.ResponseFormat? = nil,
        temperature: Double? = nil,
        topP: Double? = nil,
        stopSequence: [String] = [],
        maxOutputLength: Int? = nil,
        seed: Int? = nil,
        presencePenalty: Double? = nil,
        frequencyPenalty: Double? = nil
    ) {
        self.responseFormat = responseFormat
        self.temperature = temperature
        self.topP = topP
        self.stopSequence = stopSequence
        self.maxOutputLength = maxOutputLength
        self.seed = seed
        self.presencePenalty = presencePenalty
        self.frequencyPenalty = frequencyPenalty
    }
}


extension ChatQuery.ResponseFormat: @unchecked @retroactive Sendable {}
