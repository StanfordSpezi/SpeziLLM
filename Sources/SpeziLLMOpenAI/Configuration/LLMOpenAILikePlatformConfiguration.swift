//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable file_types_order

import Foundation
import GeneratedOpenAIClient
import OpenAPIRuntime


/// The configuration of an OpenAI-like LLM platform
public protocol LLMOpenAILikePlatformConfiguration: Sendable {
    /// Defines the models available on this platform
    associatedtype ModelType: LLMOpenAILikePlatformModelType
    
    /// The name of the platform, e.g. "OpenAI", or "Anthropic"
    static var platformName: String { get }
    /// URL of the platform's developer console website.
    ///
    /// Used in the UI when displaying API key instructions.
    static var platformDeveloperConsoleUrl: URL? { get }
    
    /// The server endpoint that the inference tasks are dispatched to.
    var serverUrl: URL { get }
    
    /// The OpenAI API token on a global basis.
    var authToken: RemoteLLMInferenceAuthToken { get }
    
    /// Indicates the maximum number of concurrent streams to the OpenAI API.
    var concurrentStreams: Int { get }
    
    /// Maximum network timeout of OpenAI requests in seconds.
    var timeout: TimeInterval { get }
    
    /// The retry policy that should be used.
    var retryPolicy: RetryPolicy { get }
    
    /// The task priority of the initiated LLM inference tasks.
    var taskPriority: TaskPriority { get }
    
    /// Additional middlewares that should be used by the client.
    ///
    /// The `ClientMiddleware` instances specified here are placed after any other middleware configured by SpeziLLM (e.g., the retry mechanism).
    var middlewares: [any ClientMiddleware] { get }
}


extension LLMOpenAILikePlatformConfiguration {
    public static var platformDeveloperConsoleUrl: URL? { nil } // swiftlint:disable:this missing_docs
}


public protocol LLMOpenAILikePlatformModelType: Hashable, RawRepresentable<String>, ExpressibleByStringLiteral, Sendable {
    /// The default model, that should be used as a fallback.
    static var `default`: Self { get }
    
    /// The list of well-known model types.
    ///
    /// Used e.g. when picking a model in the UI.
    static var wellKnownModels: [Self] { get }
}
