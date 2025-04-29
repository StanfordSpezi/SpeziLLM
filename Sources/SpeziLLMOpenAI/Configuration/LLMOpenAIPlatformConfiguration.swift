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
    public enum Defaults: Sendable {
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
    /// The OpenAI API token on a global basis.
    let authToken: RemoteLLMInferenceAuthToken
    /// Indicates the maximum number of concurrent streams to the OpenAI API.
    let concurrentStreams: Int
    /// Maximum network timeout of OpenAI requests in seconds.
    let timeout: TimeInterval
    /// The retry policy that should be used.
    let retryPolicy: RetryPolicy
    /// The task priority of the initiated LLM inference tasks.
    let taskPriority: TaskPriority

    
    /// Creates the ``LLMOpenAIPlatformConfiguration`` which configures the Spezi ``LLMOpenAIPlatform``.
    ///
    /// - Parameters:
    ///   - serverUrl: The server `URL` that the inference tasks are dispatched to. Defaults to the OpenAI API endpoint specified in the OpenAI OpenAPI document.
    ///   - authToken: Specifies the OpenAI API token on a global basis, defaults to `nil`.
    ///   - concurrentStreams: Indicates the maximum number of concurrent streams to the OpenAI API, defaults to `10`.
    ///   - timeout: Indicates the maximum network timeout of OpenAI requests in seconds. defaults to `60`.
    ///   - retryPolicy: The retry policy that should be used, defaults to `3` retry attempts.
    ///   - taskPriority: The task priority of the initiated LLM inference tasks, defaults to `.userInitiated`.
    public init(
        serverUrl: URL = Defaults.defaultServerUrl,
        authToken: RemoteLLMInferenceAuthToken = .none,
        concurrentStreams: Int = 10,
        timeout: TimeInterval = 60,
        retryPolicy: RetryPolicy = .attempts(3),
        taskPriority: TaskPriority = .userInitiated
    ) {
        self.serverUrl = serverUrl
        self.authToken = authToken
        self.concurrentStreams = concurrentStreams
        self.timeout = timeout
        self.retryPolicy = retryPolicy
        self.taskPriority = taskPriority
    }
}
