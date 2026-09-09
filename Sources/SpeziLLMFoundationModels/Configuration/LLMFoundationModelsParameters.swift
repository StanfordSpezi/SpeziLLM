//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

#if canImport(FoundationModels)
import FoundationModels
#endif
import Foundation


/// Parameters that configure inference of a ``LLMFoundationModelsSession``.
public struct LLMFoundationModelsParameters: Sendable {
    /// System prompt / instructions handed to the underlying `LanguageModelSession`.
    public let instructions: String?
    /// Temperature override. `nil` falls back to the framework default.
    public let temperature: Double?
    /// Maximum number of response tokens. `nil` falls back to the framework default.
    public let maximumResponseTokens: Int?
    /// When `true`, the schema of a `@Generable` type is included in the prompt for structured output requests.
    public let includeSchemaInPrompt: Bool

    /// Creates a new ``LLMFoundationModelsParameters`` value.
    /// - Parameters:
    ///   - instructions: System prompt handed to the `LanguageModelSession`. Defaults to `nil`.
    ///   - temperature: Sampling temperature override. Defaults to `nil`.
    ///   - maximumResponseTokens: Caps the response length. Defaults to `nil`.
    ///   - includeSchemaInPrompt: Forwarded to structured output APIs. Defaults to `true`.
    public init(
        instructions: String? = nil,
        temperature: Double? = nil,
        maximumResponseTokens: Int? = nil,
        includeSchemaInPrompt: Bool = true
    ) {
        self.instructions = instructions
        self.temperature = temperature
        self.maximumResponseTokens = maximumResponseTokens
        self.includeSchemaInPrompt = includeSchemaInPrompt
    }
}


#if canImport(FoundationModels)
@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
extension LLMFoundationModelsParameters {
    /// Maps the parameters to the framework's `GenerationOptions`.
    var generationOptions: GenerationOptions {
        GenerationOptions(
            temperature: temperature,
            maximumResponseTokens: maximumResponseTokens
        )
    }
}
#endif
