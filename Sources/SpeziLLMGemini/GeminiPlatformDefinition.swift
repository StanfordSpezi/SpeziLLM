//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable file_types_order

import Foundation
import SpeziKeychainStorage
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


// MARK: Type Specializations

/// Represents the configuration of the Spezi ``LLMGeminiPlatform``.
public typealias LLMGeminiPlatformConfiguration = LLMOpenAILikePlatformConfiguration<GeminiPlatformDefinition>


/// Represents the parameters of an Gemini LLM model.
public typealias LLMGeminiParameters = LLMOpenAILikeParameters<GeminiPlatformDefinition>


/// LLM execution platform of an Anthropic ``LLMGeminiSchema``.
///
/// - Note: This type behaves identical to SpeziLLMOpenAI's `LLMOpenAIPlatform`, except that it interacts with Gemini's APIs instead of OpenAI's; see the [`LLMOpenAIPlatform`](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillmopenai/llmopenaiplatform) documentation for further documentation.
///
/// ### Usage
///
/// The example below demonstrates the setup of the ``LLMGeminiPlatform`` within the Spezi `Configuration`.
/// ```swift
/// class TestAppDelegate: SpeziAppDelegate {
///     override var configuration: Configuration {
///         Configuration {
///             LLMRunner {
///                 LLMGeminiPlatform()
///             }
///         }
///     }
/// }
/// ```
public typealias LLMGeminiPlatform = LLMOpenAILikePlatform<GeminiPlatformDefinition>


/// Defines the type and configuration of the ``LLMGeminiSession``.
///
/// The ``LLMGeminiSchema`` is used as a configuration for the to-be-used LLMGeminiPlatform LLM. It contains all information necessary for the creation of an executable ``LLMGeminiSession``.
/// It is bound to a ``LLMGeminiPlatform`` that is responsible for turning the ``LLMGeminiSchema`` to an ``LLMGeminiSession``.
///
/// - Note: This type behaves identical to SpeziLLMOpenAI's `LLMOpenAISchema`, except that it interacts with Gemini's APIs instead of OpenAI's; see the [`LLMOpenAISchema`](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillmopenai/llmopenaischema) documentation for further documentation.
///
/// - Tip: ``LLMGeminiSchema`` also enables the function calling mechanism to establish a structured, bidirectional, and reliable communication between the ``LLMGeminiPlatform`` LLMs and external tools.
///     For more details, refer to the [`LLMOpenAISchema`](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillmopenai/llmopenaischema) documentation.
public typealias LLMGeminiSchema = LLMOpenAILikeSchema<GeminiPlatformDefinition>


/// Represents an ``LLMGeminiSchema`` in execution.
///
/// The ``LLMGeminiSession`` is the executable version of the LLMGeminiPlatform LLM containing context and state as defined by the ``LLMGeminiSchema``.
/// It provides access to text-based models from Gemini.
///
/// - Note: This type behaves identical to SpeziLLMOpenAI's `LLMGeminiSession`, except that it interacts with Gemini's APIs instead of OpenAI's; see the [`LLMOpenAISession`](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillmopenai/llmopenaisession) documentation for further documentation.
///
///
/// ### Usage
///
/// The example below demonstrates a minimal usage of the ``LLMGeminiSession`` via the `LLMRunner`.
///
/// ```swift
/// import SpeziLLM
/// import SpeziLLMGemini
/// import SwiftUI
///
/// struct LLMGeminiDemoView: View {
///     @Environment(LLMRunner.self) var runner
///     @State var responseText = ""
///
///     var body: some View {
///         Text(responseText)
///             .task {
///                 // Instantiate the `LLMGeminiSchema` to an `LLMGeminiSession` via the `LLMRunner`.
///                 let llmSession: LLMGeminiSession = runner(
///                     with: LLMGeminiSchema(
///                         parameters: .init(
///                             modelType: .gemini3_1_pro,
///                             systemPrompt: "You're a helpful assistant that answers questions from users.",
///                             overwritingToken: "abc123"
///                         )
///                     )
///                 )
///
///                 do {
///                     for try await token in try await llmSession.generate() {
///                         responseText.append(token)
///                     }
///                 } catch {
///                     // Handle errors here. E.g., you can use `ViewState` and `viewStateAlert` from SpeziViews.
///                 }
///             }
///     }
/// }
/// ```
public typealias LLMGeminiSession = LLMOpenAILikeSession<GeminiPlatformDefinition>


extension CredentialsTag {
    /// The canonical credentials tag for the Gemini API key
    public static let geminiKey = Self.for(GeminiPlatformDefinition.self)
}


// MARK: Models

// swiftlint:disable identifier_name
extension GeminiPlatformDefinition.ModelType {
    /// The default model to be used with Gemini.
    public static let `default`: Self = .gemini2_5_pro
    
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
