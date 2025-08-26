//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import GeneratedOpenAIClient


/// Represents the configuration of the Spezi ``LLMOpenAIPlatform``.
public struct LLMOpenAIRealtimePlatformConfiguration: Sendable {
    public enum ModelType: String, Sendable {
        // swiftlint:disable identifier_name

        case gpt4o_realtime = "gpt-4o-realtime-preview"
        case gpt4o_realtime_mini = "gpt-4o-mini-realtime-preview"

        // swiftlint:enable identifier_name
    }

    /// The OpenAI API token on a global basis.
    let apiToken: String?
    /// Contains the LLMRealtimeTurnDetectionSettings. If set to nil, turn detection is disabled and requires explicit generation calls.
    let turnDetectionSettings: LLMRealtimeTurnDetectionSettings?
    /// Transcription settings to transcribe user audio input into text. If set, these automatically get appended to the LLMSession's `LLMContext`
    let transcriptionSettings: LLMRealtimeTranscriptionSettings?
    let model: ModelType
    /// Indicates the maximum number of concurrent streams to the OpenAI API.
    public let concurrentStreams: Int
    /// The task priority of the initiated LLM inference tasks.
    public let taskPriority: TaskPriority

    public init(
        apiToken: String? = nil,
        turnDetectionSettings: LLMRealtimeTurnDetectionSettings? = .server(),
        transcriptionSettings: LLMRealtimeTranscriptionSettings? = .init(),
        model: ModelType = .gpt4o_realtime_mini,
        concurrentStreams: Int = 10,
        taskPriority: TaskPriority = .userInitiated,
    ) {
        self.apiToken = apiToken
        self.turnDetectionSettings = turnDetectionSettings
        self.transcriptionSettings = transcriptionSettings
        self.model = model
        self.concurrentStreams = concurrentStreams
        self.taskPriority = taskPriority
    }
}
