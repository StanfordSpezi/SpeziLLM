//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

public enum LLMRealtimeTurnDetectionSettings: Encodable, Sendable {
    /// Automatically chunks the audio based on detected periods of silence.
    case server(ServerVAD = .init())

    /// More advanced VAD that uses a turn detection model (in conjunction with VAD) to semantically
    /// estimate whether the user has finished speaking, then dynamically sets a timeout based on this probability
    case semantic(SemanticVAD = .init())

    public struct ServerVAD: Encodable, Sendable {
        /// Activation threshold for VAD (0.0 to 1.0), this defaults to 0.5.
        ///
        /// A higher threshold will require louder audio to activate the model, and thus might perform better in noisy environments.
        var threshold: Double
        /// Amount of audio to include before the VAD detected speech (in milliseconds). Defaults to 300ms.
        var prefixPaddingMs: Int = 300
        /// Duration of silence to detect speech stop (in milliseconds). Defaults to 500ms.
        ///
        /// With shorter values the model will respond more quickly, but may jump in on short pauses from the user.
        var silenceDurationMs: Int
        /// Whether or not to automatically generate a response when a VAD stop event occurs.
        var createResponse: Bool
        /// Allow new speech to interrupt and stop the model’s current response (conversation mode only).
        var interruptResponse: Bool
        
        public init(
            threshold: Double = 0.5,
            prefixPaddingMs: Int = 300,
            silenceDurationMs: Int = 500,
            createResponse: Bool = true,
            interruptResponse: Bool = true
        ) {
            self.threshold = threshold
            self.prefixPaddingMs = prefixPaddingMs
            self.silenceDurationMs = silenceDurationMs
            self.createResponse = createResponse
            self.interruptResponse = interruptResponse
        }
    }
    
    public struct SemanticVAD: Encodable, Sendable {
        public enum Eagerness: String, Encodable, Sendable {
            /// `low` will let the user take their time to speak.
            case low
            case medium
            /// `high` will chunk the audio as soon as possible.
            case high
            /// `auto` is the default value, is equivalent to medium
            case auto
        }
        
        /// Controls how eager the model is to interrupt the user
        var eagerness: Eagerness?
        /// Whether or not to automatically generate a response when a VAD stop event occurs (conversation mode only).
        var createResponse: Bool
        /// Allow new speech to interrupt and stop the model’s current response (conversation mode only).
        var interruptResponse: Bool
        
        public init(eagerness: Eagerness? = .auto, createResponse: Bool = true, interruptResponse: Bool = true) {
            self.eagerness = eagerness
            self.createResponse = createResponse
            self.interruptResponse = interruptResponse
        }
    }
    
    
    enum CodingKeys: String, CodingKey {
        case type
        case threshold
        case prefixPaddingMs = "prefix_padding_ms"
        case silenceDurationMs = "silence_duration_ms"
        case createResponse = "create_response"
        case interruptResponse = "interrupt_response"
        case eagerness
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .server(let config):
            try container.encode("server_vad", forKey: .type)
            try container.encode(config.threshold, forKey: .threshold)
            try container.encode(config.prefixPaddingMs, forKey: .prefixPaddingMs)
            try container.encode(config.silenceDurationMs, forKey: .silenceDurationMs)
            try container.encodeIfPresent(config.createResponse, forKey: .createResponse)
            try container.encodeIfPresent(config.interruptResponse, forKey: .interruptResponse)
            
        case .semantic(let config):
            try container.encode("semantic_vad", forKey: .type)
            try container.encodeIfPresent(config.eagerness, forKey: .eagerness)
            try container.encodeIfPresent(config.createResponse, forKey: .createResponse)
            try container.encodeIfPresent(config.interruptResponse, forKey: .interruptResponse)
        }
    }
}
