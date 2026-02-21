//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import GeneratedOpenAIClient
import OpenAPIRuntime
import SpeziLLMOpenAI


/// Represents the configuration of the Spezi ``LLMAnthropicPlatform``.
public struct LLMAnthropicPlatformConfiguration: LLMOpenAILikePlatformConfiguration {
    public struct ModelType: LLMOpenAILikePlatformModelType {
        public let rawValue: String
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
        public init(stringLiteral value: String) {
            self.rawValue = value
        }
    }
    
    public static let platformName = "Anthropic"
    public static let platformDeveloperConsoleUrl = URL(string: "https://platform.claude.com/settings/keys")

    /// The server endpoint that the inference tasks are dispatched to.
    public let serverUrl: URL
    /// The Anthropic API token on a global basis.
    public let authToken: RemoteLLMInferenceAuthToken
    /// Indicates the maximum number of concurrent streams to the Anthropic API.
    public let concurrentStreams: Int
    /// Maximum network timeout of API requests in seconds.
    public let timeout: TimeInterval
    /// The retry policy that should be used.
    public let retryPolicy: RetryPolicy
    /// The task priority of the initiated LLM inference tasks.
    public let taskPriority: TaskPriority
    /// Additional middlewares that should be used by the client.
    ///
    /// The `ClientMiddleware` instances specified here are placed after any other middleware configured by SpeziLLM (e.g., the retry mechanism).
    public let middlewares: [any ClientMiddleware]

    
    /// Creates the ``LLMAnthropicPlatformConfiguration`` which configures the Spezi ``LLMAnthropicPlatform``.
    ///
    /// - Parameters:
    ///   - serverUrl: The server `URL` that the inference tasks are dispatched to.
    ///   - authToken: Specifies the Anthropic API token on a global basis.
    ///   - concurrentStreams: Indicates the maximum number of concurrent streams to the Anthropic API, defaults to `10`.
    ///   - timeout: Indicates the maximum network timeout of API requests in seconds. defaults to `60`.
    ///   - retryPolicy: The retry policy that should be used, defaults to `3` retry attempts.
    ///   - taskPriority: The task priority of the initiated LLM inference tasks, defaults to `.userInitiated`.
    public init(
        serverUrl: URL = URL(string: "https://api.anthropic.com/v1")!, // swiftlint:disable:this function_default_parameter_at_end force_unwrapping
        authToken: RemoteLLMInferenceAuthToken,
        concurrentStreams: Int = 10,
        timeout: TimeInterval = 60,
        retryPolicy: RetryPolicy = .attempts(3),
        taskPriority: TaskPriority = .userInitiated,
        middlewares: [any ClientMiddleware] = []
    ) {
        self.serverUrl = serverUrl
        self.authToken = authToken
        self.concurrentStreams = concurrentStreams
        self.timeout = timeout
        self.retryPolicy = retryPolicy
        self.taskPriority = taskPriority
        self.middlewares = middlewares
    }
}


// swiftlint:disable identifier_name
extension LLMAnthropicPlatformConfiguration.ModelType {
    public static let `default`: Self = .opus4_6 // swiftlint:disable:this missing_docs
    
    public static let wellKnownModels: [Self] = [ // swiftlint:disable:this missing_docs
        .opus4_6, .sonnet4_6, .haiku4_6
    ]
    
    /// Claude Opus 4.6
    public static let opus4_6 = Self(rawValue: "claude-opus-4-6")
    /// Claude Sonnet 4.6
    public static let sonnet4_6 = Self(rawValue: "claude-sonnet-4-6")
    /// Claude Haiku 4.5
    public static let haiku4_6 = Self(rawValue: "claude-haiku-4-5")
}
// swiftlint:enable identifier_name
