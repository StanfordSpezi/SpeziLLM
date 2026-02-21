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


/// Represents the configuration of the Spezi ``LLMGeminiPlatform``.
public struct LLMGeminiPlatformConfiguration: LLMOpenAILikePlatformConfiguration {
    public struct ModelType: LLMOpenAILikePlatformModelType {
        public let rawValue: String
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
    
    public static let platformName = "Gemini"
    public static let platformDeveloperConsoleUrl = URL(string: "https://aistudio.google.com/app/api-keys")

    /// The server endpoint that the inference tasks are dispatched to.
    public let serverUrl: URL
    /// The Gemini API token on a global basis.
    public let authToken: RemoteLLMInferenceAuthToken
    /// Indicates the maximum number of concurrent streams to the Gemini API.
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

    
    /// Creates the ``LLMGeminiPlatformConfiguration`` which configures the Spezi ``LLMGeminiPlatform``.
    ///
    /// - Parameters:
    ///   - serverUrl: The server `URL` that the inference tasks are dispatched to.
    ///   - authToken: Specifies the Gemini API token on a global basis.
    ///   - concurrentStreams: Indicates the maximum number of concurrent streams to the Gemini API, defaults to `10`.
    ///   - timeout: Indicates the maximum network timeout of API requests in seconds. defaults to `60`.
    ///   - retryPolicy: The retry policy that should be used, defaults to `3` retry attempts.
    ///   - taskPriority: The task priority of the initiated LLM inference tasks, defaults to `.userInitiated`.
    public init(
        serverUrl: URL = URL(string: "https://generativelanguage.googleapis.com/v1beta/openai")!, // swiftlint:disable:this function_default_parameter_at_end force_unwrapping
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
extension LLMGeminiPlatformConfiguration.ModelType {
    public static let `default`: Self = .gemini2_5_pro // swiftlint:disable:this missing_docs
    
    public static let wellKnownModels: [Self] = [ // swiftlint:disable:this missing_docs
        .gemini3_1_pro, .gemini3_pro, .gemini3_flash,
        .gemini2_5_pro, .gemini2_5_flash, .gemini2_5_flash_lite
    ]
    
    /// Gemini 3.1 Pro
    public static let gemini3_1_pro = Self(rawValue: "gemini-3.1-pro")
    /// Gemini 3 Pro
    public static let gemini3_pro = Self(rawValue: "gemini-3-pro")
    /// Gemini 3 Flash
    public static let gemini3_flash = Self(rawValue: "gemini-3-flash")
    
    /// Gemini 2.5 Pro
    public static let gemini2_5_pro = Self(rawValue: "gemini-2.5-pro")
    /// Gemini 2.5 Flash
    public static let gemini2_5_flash = Self(rawValue: "gemini-2.5-flash")
    /// Gemini 2.5 Flash Lite
    public static let gemini2_5_flash_lite = Self(rawValue: "gemini-2.5-flash-lite")
}
// swiftlint:enable identifier_name
