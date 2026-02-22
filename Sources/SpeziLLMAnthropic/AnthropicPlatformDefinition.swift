//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziLLMOpenAI


/// Defines the Anthropic LLM platform.
public struct AnthropicPlatformDefinition: LLMOpenAILikePlatformDefinition {
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
    public static let defaultServerUrl = URL(string: "https://api.anthropic.com/v1")! // swiftlint:disable:this force_unwrapping
    public static let platformDeveloperConsoleUrl = URL(string: "https://platform.claude.com/settings/keys")
}


// swiftlint:disable identifier_name
extension AnthropicPlatformDefinition.ModelType {
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
