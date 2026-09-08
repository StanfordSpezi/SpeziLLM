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


public protocol LLMOpenAILikePlatformModelType: Hashable, RawRepresentable<String>, Codable, Identifiable, ExpressibleByStringLiteral, Sendable {
    /// The default model, that should be used as a fallback.
    static var `default`: Self { get }
    
    /// The list of well-known model types.
    ///
    /// Used e.g. when picking a model in the UI.
    static var wellKnownModels: [Self] { get }

    /// Whether this model accepts the sampling parameters of the completions API.
    ///
    /// A model that has moved past them rejects `temperature`, `top_p`, the penalties and `logit_bias` with a
    /// `400` rather than ignoring them, so a caller that sets one fails every request. Reasoning models were the
    /// first to do this and the other vendors have followed, model by model rather than family by family — which
    /// is why each platform answers for its own models instead of the answer being inferred from the identifier.
    ///
    /// Defaults to `true`.
    var acceptsSamplingParameters: Bool { get }

    /// Creates a `ModelType` from a raw string value
    init(rawValue: String)
}


extension LLMOpenAILikePlatformModelType {
    public var id: some Hashable { // swiftlint:disable:this missing_docs
        rawValue
    }

    public var acceptsSamplingParameters: Bool { // swiftlint:disable:this missing_docs
        true
    }
}
