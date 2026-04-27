//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable file_types_order identifier_name force_unwrapping

import Foundation
import SpeziLLMOpenAI


// MARK: Mistral

struct MistralPlatformDefinition: LLMOpenAILikePlatformDefinition {
    struct ModelType: LLMOpenAILikePlatformModelType {
        let modelId: String
        var apiMode: LLMOpenAIAPIMode { .chatCompletions }
    }
    static let platformName: String = "Mistral"
    static let defaultServerUrl = URL(string: "https://api.mistral.ai/v1")!
    static let platformServiceIdentifier: String = "api.mistral.ai"
}

extension MistralPlatformDefinition.ModelType {
    static let `default`: Self = .small_latest
    static let wellKnownModels: [Self] = [.small_latest]
    
    static let small_latest = Self(modelId: "mistral-small-latest")
}

typealias MistralLLMPlatform = LLMOpenAILikePlatform<MistralPlatformDefinition>
typealias MistralLLMSchema = LLMOpenAILikeSchema<MistralPlatformDefinition>
typealias MistralLLMSession = LLMOpenAILikeSession<MistralPlatformDefinition>


// MARK: DeepSeek

struct DeepSeekPlatformDefinition: LLMOpenAILikePlatformDefinition {
    struct ModelType: LLMOpenAILikePlatformModelType {
        let modelId: String
        var apiMode: LLMOpenAIAPIMode { .chatCompletions }
    }
    static let platformName: String = "DeepSeek"
    static let defaultServerUrl = URL(string: "https://api.deepseek.com")!
    static let platformServiceIdentifier: String = "api.deepseek.com"
}

extension DeepSeekPlatformDefinition.ModelType {
    static let `default`: Self = .v4_flash
    static let wellKnownModels: [Self] = [.v4_flash, .v4_pro]
    
    static let v4_flash = Self(modelId: "deepseek-v4-flash")
    static let v4_pro = Self(modelId: "deepseek-v4-pro")
}

typealias DeepSeekLLMPlatform = LLMOpenAILikePlatform<DeepSeekPlatformDefinition>
typealias DeepSeekLLMSchema = LLMOpenAILikeSchema<DeepSeekPlatformDefinition>
typealias DeepSeekLLMSession = LLMOpenAILikeSession<DeepSeekPlatformDefinition>
