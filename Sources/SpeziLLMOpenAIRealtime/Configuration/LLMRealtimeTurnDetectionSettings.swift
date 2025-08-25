//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

public struct LLMRealtimeTurnDetectionSettings: Encodable, Sendable {
    public enum VADMode: String, Encodable, Sendable {
        /// Automatically chunks the audio based on detected periods of silence.
        case server = "server_vad"
    }

    /// Specifies the Voice Activity Detection (VAD) mode for audio processing.
    ///
    /// If set to `nil`, this disables VAD, in which case the client must manually trigger model response.
    let type: VADMode?

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
    
    public init(
        type: VADMode? = VADMode.server,
        threshold: Double = 0.5,
        prefixPaddingMs: Int = 300,
        silenceDurationMs: Int = 500,
        createResponse: Bool = true
    ) {
        self.type = type
        self.threshold = threshold
        self.prefixPaddingMs = prefixPaddingMs
        self.silenceDurationMs = silenceDurationMs
        self.createResponse = createResponse
    }
}
