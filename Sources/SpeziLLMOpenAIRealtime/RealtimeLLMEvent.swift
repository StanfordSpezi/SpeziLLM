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
    case userTranscriptDelta(TranscriptDelta)
    case userTranscriptDone(TranscriptDone)
    case assistantTranscriptDelta(String)
    case assistantTranscriptDone(String)
    case toolCall(Data)
    case speechStarted(SpeechStarted)
    case speechStopped
    
    public struct TranscriptDone: Sendable, Codable {
        enum CodingKeys: String, CodingKey {
            case transcript
            case itemId = "item_id"
        }

        let transcript: String
        let itemId: String
        // Non-exhaustive yet...
    }
    
    public struct TranscriptDelta: Sendable, Codable {
        enum CodingKeys: String, CodingKey {
            case delta
            case itemId = "item_id"
        }

        let delta: String
        let itemId: String
        // Non-exhaustive yet...
    }
    
    public struct SpeechStarted: Sendable, Codable {
        enum CodingKeys: String, CodingKey {
            case itemId = "item_id"
            case audioStartMs = "audio_start_ms"
        }

        let itemId: String
        let audioStartMs: Int
    }
    
    public struct FunctionCall: Sendable, Codable {
        enum CodingKeys: String, CodingKey {
            case itemId = "item_id"
            case callId = "call_id"
            case name
            case arguments
        }
        
        let itemId: String
        let callId: String
        let name: String
        let arguments: String
    }
}
