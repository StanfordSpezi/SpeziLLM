//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import GeneratedOpenAIClient
import SpeziLLM


public struct OpenAIPlatformDefinition: LLMOpenAILikePlatformDefinition {
    public struct ModelType: LLMOpenAILikePlatformModelType {
        /// The identifier of the underlying model.
        public let rawValue: String
        /// Creates a new `ModelType`
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
        /// Creates a new `ModelType`
        public init(stringLiteral rawValue: String) {
            self.rawValue = rawValue
        }
    }
    
    
    public static let platformName = "OpenAI"
    public static let platformDeveloperConsoleUrl = URL(string: "https://platform.openai.com/account/api-keys")
    public static let defaultServerUrl: URL = {
        guard let url = try? Servers.Server1.url() else {
            fatalError("The default OpenAI API endpoint couldn't be extracted from the OpenAI OpenAPI document.")
        }
        return url
    }()
}


// MARK: Models

// swiftlint:disable identifier_name missing_docs
extension OpenAIPlatformDefinition.ModelType {
    public static let `default`: Self = .gpt4o
    
    public static let wellKnownModels: [Self] = [
        .gpt5, .gpt5_mini, .gpt5_nano, .gpt5_chat,
        .gpt4o, .gpt4o_mini,
        .gpt4_turbo,
        .gpt4_1, .gpt4_1_mini, .gpt4_1_nano,
        .o4_mini,
        .o3, .o3_pro, .o3_mini, .o3_mini_high,
        .o1_pro, .o1, .o1_mini,
        .gpt3_5_turbo
    ]
    
    // GPT-5 series
    public static let gpt5 = Self(rawValue: "gpt-5")
    public static let gpt5_mini = Self(rawValue: "gpt-5-mini")
    public static let gpt5_nano = Self(rawValue: "gpt-5-nano")
    public static let gpt5_chat = Self(rawValue: "gpt-5-chat-latest")

    // GPT-4 series
    public static let gpt4o = Self(rawValue: "gpt-4o")
    public static let gpt4o_mini = Self(rawValue: "gpt-4o-mini")
    public static let gpt4_turbo = Self(rawValue: "gpt-4-turbo")
    public static let gpt4_1 = Self(rawValue: "gpt-4.1")
    public static let gpt4_1_mini = Self(rawValue: "gpt-4.1-mini")
    public static let gpt4_1_nano = Self(rawValue: "gpt-4.1-nano")

    // o-series
    public static let o4_mini = Self(rawValue: "o4-mini")
    public static let o3 = Self(rawValue: "o3")
    public static let o3_pro = Self(rawValue: "o3-pro")
    public static let o3_mini = Self(rawValue: "o3-mini")
    public static let o3_mini_high = Self(rawValue: "o3-mini-high")
    public static let o1_pro = Self(rawValue: "o1-pro")
    public static let o1 = Self(rawValue: "o1")
    public static let o1_mini = Self(rawValue: "o1-mini")

    // Others
    public static let gpt3_5_turbo = Self(rawValue: "gpt-3.5-turbo")
}
