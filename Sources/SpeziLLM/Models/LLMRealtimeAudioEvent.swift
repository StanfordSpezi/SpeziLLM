//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


public enum LLMRealtimeAudioEvent: Sendable {
    case audioDelta(Data)
    case audioDone(Data)
    case userTranscriptDelta(TranscriptDelta)
    case userTranscriptDone(TranscriptDone)
    case assistantTranscriptDelta(String)
    case assistantTranscriptDone(String)
    case speechStarted(SpeechStarted)
    case speechStopped(SpeechStopped)
    
    
    public struct TranscriptDone: Sendable, Codable {
        enum CodingKeys: String, CodingKey {
            case transcript
            case itemId = "item_id"
        }
        
        public let transcript: String
        public let itemId: String
    }
    
    public struct TranscriptDelta: Sendable, Codable {
        enum CodingKeys: String, CodingKey {
            case delta
            case itemId = "item_id"
        }
        
        public let delta: String
        public let itemId: String
    }
    
    public struct SpeechStarted: Sendable, Decodable {
        enum CodingKeys: String, CodingKey {
            case itemId = "item_id"
            case audioStartMs = "audio_start_ms"
        }
        
        public let itemId: String
        public let audioStart: Duration
        
        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            itemId = try container.decode(String.self, forKey: .itemId)
            
            let audioStartMs = try container.decode(Int.self, forKey: .audioStartMs)
            audioStart = .milliseconds(audioStartMs)
        }
    }
    
    public struct SpeechStopped: Sendable, Decodable {
        enum CodingKeys: String, CodingKey {
            case itemId = "item_id"
            case audioEndMs = "audio_end_ms"
        }

        public let itemId: String
        public let audioEnd: Duration

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            itemId = try container.decode(String.self, forKey: .itemId)

            let audioEndMs = try container.decode(Int.self, forKey: .audioEndMs)
            audioEnd = .milliseconds(audioEndMs)
        }
    }
}
