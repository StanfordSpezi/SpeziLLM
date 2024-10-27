//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// Represents the sampling parameters of the LLM.
public struct LLMLocalSamplingParameters: Sendable {    // swiftlint:disable:this type_body_length
    /// Top-p Sampling: Smallest possible set of words whose cumulative probability exceeds the probability p (1.0 = disabled).
    let topP: Float
    /// Temperature Sampling: A higher value indicates more creativity of the model but also more hallucinations.
    let temperature: Float
    /// Penalize repeated tokens (nil = disabled).
    let penaltyRepeat: Float?
    /// Number of tokens to consider for repetition penalty
    let repetitionContextSize: Int


    /// Creates the ``LLMLocalContextParameters``
    ///
    /// - Parameters:
    ///   - topP: Top-p Sampling: Smallest possible set of words whose cumulative probability exceeds the probability p (1.0 = disabled).
    ///   - temperature: Temperature Sampling: A higher value indicates more creativity of the model but also more hallucinations.
    ///   - penaltyRepeat: Penalize repeated tokens (nil = disabled).
    ///   - repetitionContextSize: Number of tokens to consider for repetition penalty
    public init(
        topP: Float = 1.0,
        temperature: Float = 0.6,
        penaltyRepeat: Float? = nil,
        repetitionContextSize: Int = 20
    ) {
        self.topP = topP
        self.temperature = temperature
        self.penaltyRepeat = penaltyRepeat
        self.repetitionContextSize = repetitionContextSize
    }
}
