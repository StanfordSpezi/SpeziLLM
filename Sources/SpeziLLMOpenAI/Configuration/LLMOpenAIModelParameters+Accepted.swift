//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import GeneratedOpenAIClient
import os


extension LLMOpenAIModelParameters {
    private static let logger = Logger(subsystem: "edu.stanford.spezi", category: "SpeziLLMOpenAI")


    /// The same parameters, without the sampling parameters the given model refuses.
    ///
    /// Sending one to a model that has moved past them fails the request outright, which would turn a parameter a
    /// caller set once into an app whose every answer errors. Dropping them costs the caller the control it asked
    /// for and nothing else, so the session keeps answering; the dropped parameters are logged, because the call
    /// site is where this is worth fixing.
    func accepted(by modelType: some LLMOpenAILikePlatformModelType) -> Self {
        guard !modelType.acceptsSamplingParameters else {
            return self
        }

        var dropped: [String] = []
        var accepted = self
        if temperature != nil {
            dropped.append("temperature")
            accepted.temperature = nil
        }
        if topP != nil {
            dropped.append("topP")
            accepted.topP = nil
        }
        if presencePenalty != nil {
            dropped.append("presencePenalty")
            accepted.presencePenalty = nil
        }
        if frequencyPenalty != nil {
            dropped.append("frequencyPenalty")
            accepted.frequencyPenalty = nil
        }
        if !logitBias.additionalProperties.isEmpty {
            dropped.append("logitBias")
            accepted.logitBias = .init(additionalProperties: [:])
        }

        guard !dropped.isEmpty else {
            return self
        }

        Self.logger.warning(
            """
            \(modelType.rawValue, privacy: .public) does not accept sampling parameters; \
            dropped \(dropped.joined(separator: ", "), privacy: .public) from the request. \
            Remove them from the schema's `modelParameters` and steer the model through the prompt instead.
            """
        )
        return accepted
    }
}
