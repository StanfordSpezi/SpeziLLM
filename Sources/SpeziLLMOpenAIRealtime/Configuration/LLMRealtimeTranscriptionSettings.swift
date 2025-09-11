//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziFoundation


public struct LLMRealtimeTranscriptionSettings: Sendable {
    public enum TranscriptionModel: String, Sendable {
        case gpt4oTranscribe = "gpt-4o-transcribe"
        case gpt4oMiniTranscribe = "gpt-4o-mini-transcribe"
        case whisper1 = "whisper-1"
    }

    /// The transcription model to use
    let model: TranscriptionModel
    /// The language to use for the transcription, ideally in ISO-639-1 format (e.g. "en", "fr"...) to improve accuracy and latency
    let language: String?
    /// The prompt to use for the transcription, to guide the model (e.g. "Expect words related to technology")
    let prompt: String?
    
    public init(model: TranscriptionModel = .gpt4oMiniTranscribe, language: String? = nil, prompt: String? = nil) {
        self.model = model
        self.language = language
        self.prompt = prompt
    }
}
