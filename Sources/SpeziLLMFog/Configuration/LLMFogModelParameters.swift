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


/// Represents the model-specific parameters of Fog LLMs.
public struct LLMFogModelParameters: Sendable {
    /// The response format of the LLM.
    public enum ResponseFormat {
        case text
        case jsonObject


        var openAiRepresentation: Components.Schemas.CreateChatCompletionRequest.Value2Payload.response_formatPayload {
            switch self {
            case .text:
                .text(.init(_type: .text))
            case .jsonObject:
                .json_object(.init(_type: .json_object))
            }
        }
    }


    /// The format for model responses.
    let responseFormat: Components.Schemas.CreateChatCompletionRequest.Value2Payload.response_formatPayload?
    /// The sampling temperature (0 to 2). Higher values increase randomness, lower values enhance focus.
    let temperature: Double?
    /// Nucleus sampling threshold. Considers tokens with top_p probability mass. Alternative to temperature sampling.
    let topP: Double?
    /// Sequences (up to 4) where generation stops. Output doesn't include these sequences.
    let stopSequence: [String]
    /// Maximum token count for each completion.
    let maxOutputLength: Int?
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
    ///   - presencePenalty: Adjusts new topic exploration (-2.0 to 2.0); higher values encourage novelty.
    ///   - frequencyPenalty: Controls repetition (-2.0 to 2.0); higher values reduce likelihood of repeating content.
    public init(
        responseFormat: ResponseFormat? = nil,
        temperature: Double? = nil,
        topP: Double? = nil,
        stopSequence: [String] = [],
        maxOutputLength: Int? = nil,
        presencePenalty: Double? = nil,
        frequencyPenalty: Double? = nil
    ) {
        self.responseFormat = responseFormat?.openAiRepresentation
        self.temperature = temperature
        self.topP = topP
        self.stopSequence = stopSequence
        self.maxOutputLength = maxOutputLength
        self.presencePenalty = presencePenalty
        self.frequencyPenalty = frequencyPenalty
    }

    /// Initializes ``LLMFogModelParameters`` for Fog LLM model configuration.
    ///
    /// - Parameters:
    ///   - responseFormat: Format for model responses.
    ///   - temperature: Sampling temperature (0 to 2); higher values (e.g., 0.8) increase randomness, lower values (e.g., 0.2) enhance focus. Adjust this or topP, not both.
    ///   - topP: Nucleus sampling threshold; considers tokens with top_p probability mass. Alternative to temperature sampling.
    ///   - stopSequence: Sequences (up to 4) where generation stops; output doesn't include these sequences.
    ///   - maxOutputLength: Maximum token count for each completion.
    ///   - seed: No longer sent. OpenAI has retired the `seed` parameter from the API the fog node implements.
    ///   - presencePenalty: Adjusts new topic exploration (-2.0 to 2.0); higher values encourage novelty.
    ///   - frequencyPenalty: Controls repetition (-2.0 to 2.0); higher values reduce likelihood of repeating content.
    @available(*, deprecated, message: "OpenAI has retired the `seed` parameter, which is no longer sent. Use the initializer without it.")
    // swiftlint:disable function_default_parameter_at_end
    public init(
        responseFormat: ResponseFormat? = nil,
        temperature: Double? = nil,
        topP: Double? = nil,
        stopSequence: [String] = [],
        maxOutputLength: Int? = nil,
        seed: Int?,
        presencePenalty: Double? = nil,
        frequencyPenalty: Double? = nil
    ) {
        self.init(
            responseFormat: responseFormat,
            temperature: temperature,
            topP: topP,
            stopSequence: stopSequence,
            maxOutputLength: maxOutputLength,
            presencePenalty: presencePenalty,
            frequencyPenalty: frequencyPenalty
        )
    }
    // swiftlint:enable function_default_parameter_at_end
}
