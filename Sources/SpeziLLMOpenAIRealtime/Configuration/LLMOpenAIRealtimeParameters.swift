//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import GeneratedOpenAIClient


/// Represents the parameters of OpenAIs Realtime LLMs.
public struct LLMOpenAIRealtimeParameters: Sendable {
    public enum ModelType: String, Sendable {
        // swiftlint:disable identifier_name

        case gpt4o_realtime = "gpt-4o-realtime-preview"
        case gpt4o_realtime_mini = "gpt-4o-mini-realtime-preview"
        case gpt_realtime = "gpt-realtime"

        // swiftlint:enable identifier_name
    }
    
    /// Defaults of possible LLMs Realtime parameter settings.
    public enum Defaults {
        public static let turnDetectionSettings: LLMRealtimeTurnDetectionSettings = .semantic()
        public static let transcriptionSettings: LLMRealtimeTranscriptionSettings = .init()
    }


    /// The to-be-used OpenAI model.
    let modelType: String
    
    /// Contains the LLMRealtimeTurnDetectionSettings. If set to nil, turn detection is disabled and requires explicit generation calls.
    let turnDetectionSettings: LLMRealtimeTurnDetectionSettings?
    /// Transcription settings to transcribe user audio input into text. If set, these automatically get appended to the LLMSession's `LLMContext`
    let transcriptionSettings: LLMRealtimeTranscriptionSettings?

    public init(
        modelType: ModelType,
        turnDetectionSettings: LLMRealtimeTurnDetectionSettings? = Defaults.turnDetectionSettings,
        transcriptionSettings: LLMRealtimeTranscriptionSettings? = Defaults.transcriptionSettings,
    ) {
        self.modelType = modelType.rawValue
        self.turnDetectionSettings = turnDetectionSettings
        self.transcriptionSettings = transcriptionSettings
    }
}
