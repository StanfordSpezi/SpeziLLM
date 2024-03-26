//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// Represents the configuration of the Spezi ``LLMOpenAIPlatform``.
public struct LLMOpenAIPlatformConfiguration: Sendable {
    /// The task priority of the initiated LLM inference tasks.
    let taskPriority: TaskPriority
    /// Indicates the number of concurrent streams to the OpenAI API.
    let concurrentStreams: Int
    /// The OpenAI API token on a global basis.
    let apiToken: String?
    /// Maximum network timeout of OpenAI requests in seconds.
    let timeout: TimeInterval
    
    
    /// Creates the ``LLMOpenAIPlatformConfiguration`` which configures the Spezi ``LLMOpenAIPlatform``.
    ///
    /// - Parameters:
    ///   - taskPriority: The task priority of the initiated LLM inference tasks, defaults to `.userInitiated`.
    ///   - concurrentStreams: Indicates the number of concurrent streams to the OpenAI API, defaults to `10`.
    ///   - apiToken: Specifies the OpenAI API token on a global basis, defaults to `nil`.
    ///   - timeout: Indicates the maximum network timeout of OpenAI requests in seconds. defaults to `60`.
    public init(
        taskPriority: TaskPriority = .userInitiated,
        concurrentStreams: Int = 10,
        apiToken: String? = nil,
        timeout: TimeInterval = 60
    ) {
        self.taskPriority = taskPriority
        self.concurrentStreams = concurrentStreams
        self.apiToken = apiToken
        self.timeout = timeout
    }
}
