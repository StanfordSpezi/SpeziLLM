//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

public struct LLMRealtimeTurnDetectionSettings: Encodable, Sendable {
    /// Type of turn detection, only `"server_vad"` is currently supported.
    let type: String = "server_vad"
    /// Activation threshold for VAD (0.0 to 1.0), this defaults to 0.5.
    ///
    /// A higher threshold will require louder audio to activate the model, and thus might perform better in noisy environments.
    let threshold: Double
    /// Amount of audio to include before the VAD detected speech (in milliseconds). Defaults to 300ms.
    let prefixPaddingMs: Int
    /// Duration of silence to detect speech stop (in milliseconds). Defaults to 500ms.
    ///
    /// With shorter values the model will respond more quickly, but may jump in on short pauses from the user.
    let silenceDurationMs: Int
    
    /// Whether or not to automatically generate a response when a VAD stop event occurs.
    let createResponse: Bool
    
    public init(threshold: Double = 0.5, prefixPaddingMs: Int = 300, silenceDurationMs: Int = 500, createResponse: Bool = true) {
        self.threshold = threshold
        self.prefixPaddingMs = prefixPaddingMs
        self.silenceDurationMs = silenceDurationMs
        self.createResponse = createResponse
    }
}
