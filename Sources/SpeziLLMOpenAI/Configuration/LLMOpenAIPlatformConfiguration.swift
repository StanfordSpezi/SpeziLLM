//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import GeneratedOpenAIClient


/// Represents the configuration of the Spezi ``LLMOpenAIPlatform``.
public struct LLMOpenAIPlatformConfiguration: Sendable {
    /// Default configurations of the ``LLMOpenAIPlatform``.
    public enum Defaults {
        /// Default server `URL` that the inference tasks are dispatched to.
        public static let defaultServerUrl: URL = {
            guard let url = try? Servers.Server1.url() else {
                preconditionFailure("The default OpenAI API endpoint couldn't be extracted from the OpenAI OpenAPI document.")
            }

            return url
        }()
    }

    /// The server endpoint that the inference tasks are dispatched to.
    let serverUrl: URL
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
    ///   - serverUrl: The server `URL` that the inference tasks are dispatched to. Defaults to the OpenAI API endpoint specified in the OpenAI OpenAPI document.
    ///   - apiToken: Specifies the OpenAI API token on a global basis, defaults to `nil`.
    ///   - concurrentStreams: Indicates the number of concurrent streams to the OpenAI API, defaults to `10`.
    ///   - timeout: Indicates the maximum network timeout of OpenAI requests in seconds. defaults to `60`.
    ///   - taskPriority: The task priority of the initiated LLM inference tasks, defaults to `.userInitiated`.
    public init(
        serverUrl: URL = Defaults.defaultServerUrl,
        apiToken: String? = nil,
        concurrentStreams: Int = 10,
        timeout: TimeInterval = 60,
        taskPriority: TaskPriority = .userInitiated,
    ) {
        self.serverUrl = serverUrl
        self.apiToken = apiToken
        self.concurrentStreams = concurrentStreams
        self.timeout = timeout
        self.taskPriority = taskPriority
    }
}
