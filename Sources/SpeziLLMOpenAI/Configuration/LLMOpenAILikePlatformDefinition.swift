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
    
    /// URL of the platform's developer console website.
    ///
    /// Used in the UI when displaying API key instructions.
    static var platformDeveloperConsoleUrl: URL? { get }
}


extension LLMOpenAILikePlatformDefinition {
    public static var platformDeveloperConsoleUrl: URL? { nil } // swiftlint:disable:this missing_docs
}


public protocol LLMOpenAILikePlatformModelType: Hashable, RawRepresentable<String>, Identifiable, ExpressibleByStringLiteral, Sendable {
    /// The default model, that should be used as a fallback.
    static var `default`: Self { get }
    
    /// The list of well-known model types.
    ///
    /// Used e.g. when picking a model in the UI.
    static var wellKnownModels: [Self] { get }
}


extension LLMOpenAILikePlatformModelType {
    public var id: some Hashable { // swiftlint:disable:this missing_docs
        rawValue
    }
}
