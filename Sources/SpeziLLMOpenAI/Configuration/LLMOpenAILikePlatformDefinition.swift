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


/// The API mode to use for inference with an OpenAI-like platform.
public enum LLMOpenAIAPIMode: String, Encodable, Sendable {
    /// The `/v1/chat/completions` API
    case chatCompletions
    /// The `/v1/responses` API
    case responses
}


public protocol LLMOpenAILikePlatformDefinition: Sendable {
    /// Defines the models available on this platform
    associatedtype ModelType: LLMOpenAILikePlatformModelType
    
    /// The name of the platform, e.g. "OpenAI", or "Anthropic"
    static var platformName: String { get }
    
    /// The platform's default server endpoint that inference tasks should be dispatched to.
    static var defaultServerUrl: URL { get }
    
    /// A URL-like identifier used as the service name when storing API keys for this platform to the keychain.
    ///
    /// This does not have to be a live URL; it just needs to uniquely identify the platform.
    /// For example, the identifier for the ``OpenAIPlatformDefinition`` is `api.openai.com`.
    static var platformServiceIdentifier: String { get }
    
    /// URL of the platform's developer console website.
    ///
    /// Used in the UI when displaying API key instructions.
    static var platformDeveloperConsoleUrl: URL? { get }
}


extension LLMOpenAILikePlatformDefinition {
    public static var platformDeveloperConsoleUrl: URL? { nil } // swiftlint:disable:this missing_docs
}


public protocol LLMOpenAILikePlatformModelType: Hashable, Encodable, Sendable {
    /// The default model, that should be used as a fallback.
    static var `default`: Self { get }
    
    /// The list of well-known model types.
    ///
    /// Used e.g. when picking a model in the UI.
    static var wellKnownModels: [Self] { get }
    
    /// The model identifier
    var modelId: String { get }
    
    /// The API mode to use for inference with this model.
    var apiMode: LLMOpenAIAPIMode { get }
    
    /// Whether this model can emit reasoning summaries during inference.
    ///
    /// When `true`, SpeziLLMOpenAI will include `reasoning.summary = .auto` in requests made via the responses API, the resulting summaries will be propagated into the `LLMContext`.
    /// Defaults to `false`.
    var supportsReasoningSummary: Bool { get }
}


extension LLMOpenAILikePlatformModelType {
    public var supportsReasoningSummary: Bool { // swiftlint:disable:this missing_docs
        false
    }
}
