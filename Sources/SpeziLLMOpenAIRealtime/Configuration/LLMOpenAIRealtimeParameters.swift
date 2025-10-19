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

        case gpt4oRealtime = "gpt-4o-realtime-preview"
        case gpt4oRealtime_mini = "gpt-4o-mini-realtime-preview"
        case gptRealtime = "gpt-realtime"

        // swiftlint:enable identifier_name
    }
    
    public enum OpenAIVoice: String, Sendable {
        /// Neutral and balanced
        case alloy
        /// Clear and precise
        case ash
        /// Melodic and smooth
        case ballad
        /// Warm and friendly
        case coral
        /// Resonant and deep
        case echo
        /// Calm and thoughtful
        case sage
        /// Bright and energetic
        case shimmer
        /// Versatile and expressive
        case verse
        
        public static let `default`: OpenAIVoice = .alloy
    }
    
    /// Defaults of possible LLMs Realtime parameter settings.
    public enum Defaults {
        public static let defaultSystemPrompt: String = {
            String(localized: LocalizedStringResource("SPEZI_LLM_OPENAI_REALTIME_SYSTEM_PROMPT", bundle: .atURL(from: .module)))
        }()
        public static let turnDetectionSettings: LLMRealtimeTurnDetectionSettings = .default
        public static let transcriptionSettings: LLMRealtimeTranscriptionSettings = .default
        public static let voice: OpenAIVoice = .default
    }


    /// The to-be-used OpenAI model.
    let modelType: String
    /// The to-be-used system prompt of the Realtime Session.
    let systemPrompt: String?
    /// Contains the LLMRealtimeTurnDetectionSettings. If set to nil, turn detection is disabled and requires explicit generation calls.
    let turnDetectionSettings: LLMRealtimeTurnDetectionSettings?
    /// Transcription settings to transcribe user audio input into text. If set, these automatically get appended to the LLMSession's `LLMContext`
    let transcriptionSettings: LLMRealtimeTranscriptionSettings?
    /// The voice to use for the assistant's audio output.
    let voice: OpenAIVoice?
    
    /// Creates the ``LLMOpenAIRealtimeParameters``.
    ///
    /// - Parameters:
    ///   - modelType: The OpenAI Realtime model to use (`gpt4oRealtime`, `gpt4oRealtime_mini`, or `gptRealtime`).
    ///   - systemPrompt: The system prompt to guide the model's behavior.
    ///   - turnDetectionSettings: Voice Activity Detection (VAD) settings to automatically detect when the user has finished speaking.
    ///                            Set to `nil` to disable automatic turn detection and require manual `endUserTurn()` calls.
    ///   - transcriptionSettings: Transcription settings to transcribe user audio input into text. If set, these automatically get appended to the LLMSession's `LLMContext`.
    ///   - voice: The voice to use for the assistant's audio output.
    public init(
        modelType: ModelType,
        systemPrompt: String? = Defaults.defaultSystemPrompt,
        turnDetectionSettings: LLMRealtimeTurnDetectionSettings? = Defaults.turnDetectionSettings,
        transcriptionSettings: LLMRealtimeTranscriptionSettings? = Defaults.transcriptionSettings,
        voice: OpenAIVoice? = Defaults.voice
    ) {
        self.modelType = modelType.rawValue
        self.systemPrompt = systemPrompt
        self.turnDetectionSettings = turnDetectionSettings
        self.transcriptionSettings = transcriptionSettings
        self.voice = voice
    }
}
