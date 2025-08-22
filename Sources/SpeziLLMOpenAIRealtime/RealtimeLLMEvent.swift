//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Foundation

public enum RealtimeLLMEvent: Sendable {
    case audioDelta(Data)
    case audioDone(Data)
    case userTranscriptDelta(TranscriptDeltaEvent)
    case userTranscriptDone(TranscriptDoneEvent)
    case assistantTranscriptDelta(String)
    case assistantTranscriptDone(String)
    case toolCall(Data)
    case speechStarted(SpeechStartedEvent)
    case speechStopped
}

public struct TranscriptDoneEvent: Sendable, Codable {
    enum CodingKeys: String, CodingKey {
        case transcript
        case itemId = "item_id"
    }

    let transcript: String
    let itemId: String
    // Non-exhaustive yet...
}

public struct TranscriptDeltaEvent: Sendable, Codable {
    enum CodingKeys: String, CodingKey {
        case delta
        case itemId = "item_id"
    }

    let delta: String
    let itemId: String
    // Non-exhaustive yet...
}

public struct SpeechStartedEvent: Sendable, Codable {
    enum CodingKeys: String, CodingKey {
        case itemId = "item_id"
        case audioStartMs = "audio_start_ms"
    }

    let itemId: String
    let audioStartMs: Int
}
