//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziLLMOpenAI


/// Defines the Gemini LLM platform.
public struct GeminiPlatformDefinition: LLMOpenAILikePlatformDefinition {
    public struct ModelType: LLMOpenAILikePlatformModelType {
        public let rawValue: String
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
        public init(stringLiteral value: String) {
            self.rawValue = value
        }
    }
    
    public static let platformName = "Gemini"
    public static let platformServiceIdentifier = "generativelanguage.googleapis.com"
    
    public static let defaultServerUrl = URL(string: "https://generativelanguage.googleapis.com/v1beta/openai")! // swiftlint:disable:this force_unwrapping
    
    public static let platformDeveloperConsoleUrl = URL(string: "https://aistudio.google.com/app/api-keys")
}


// swiftlint:disable identifier_name
extension GeminiPlatformDefinition.ModelType {
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
