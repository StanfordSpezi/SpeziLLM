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
    /// The OpenAI API token on a global basis.
    let apiToken: String?
    /// Contains the LLMRealtimeTurnDetectionSettings. If set to nil, turn detection is disabled and requires explicit generation calls.
    let turnDetectionSettings: LLMRealtimeTurnDetectionSettings?
    /// Indicates the maximum number of concurrent streams to the OpenAI API.
    public let concurrentStreams: Int
    /// The task priority of the initiated LLM inference tasks.
    public let taskPriority: TaskPriority

    public init(
        apiToken: String? = nil,
        turnDetectionSettings: LLMRealtimeTurnDetectionSettings? = nil,
        concurrentStreams: Int = 10,
        taskPriority: TaskPriority = .userInitiated
    ) {
        self.apiToken = apiToken
        self.turnDetectionSettings = turnDetectionSettings
        self.concurrentStreams = concurrentStreams
        self.taskPriority = taskPriority
    }
}
