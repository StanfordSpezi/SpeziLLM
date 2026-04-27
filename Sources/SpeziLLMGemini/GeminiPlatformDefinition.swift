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
        public let modelId: String
        public var apiMode: LLMOpenAIAPIMode {
            // all gemini models are run via their OpenAI compatibility layer, which supports only the chat completions API
            .chatCompletions
        }
        
        public init(modelId: String) {
            self.modelId = modelId
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


/// Represents the parameters of a Gemini LLM model.
public typealias LLMGeminiParameters = LLMOpenAILikeParameters<GeminiPlatformDefinition>


/// LLM execution platform of a ``LLMGeminiSchema``.
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
/// - Note: This type behaves identical to SpeziLLMOpenAI's `LLMOpenAISession`, except that it interacts with Gemini's APIs instead of OpenAI's; see the [`LLMOpenAISession`](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillmopenai/llmopenaisession) documentation for further documentation.
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
///                             overwritingAuthToken: "abc123"
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


/// View to display an onboarding step for the user to enter a Gemini API Key.
///
/// - Warning: Ensure that the ``LLMGeminiPlatform`` is specified within the Spezi `Configuration` when using this view in the onboarding flow.
///
/// - Important: Only use this if the corresponding LLM platform's config's auth token is set to `RemoteLLMInferenceAuthToken/keychain(_:CredentialsTag)`
public typealias LLMGeminiAPITokenOnboardingStep = LLMOpenAILikeAPITokenOnboardingStep<GeminiPlatformDefinition>


/// View to display an onboarding step for the user to select a Gemini model.
public typealias LLMGeminiModelOnboardingStep = LLMOpenAILikeModelOnboardingStep<GeminiPlatformDefinition>


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
    
    // swiftlint:disable missing_docs
    public static let gemini3_1_pro = Self(modelId: "gemini-3.1-pro")
    public static let gemini3_pro = Self(modelId: "gemini-3-pro")
    public static let gemini3_flash = Self(modelId: "gemini-3-flash")
    
    public static let gemini2_5_pro = Self(modelId: "gemini-2.5-pro")
    public static let gemini2_5_flash = Self(modelId: "gemini-2.5-flash")
    public static let gemini2_5_flash_lite = Self(modelId: "gemini-2.5-flash-lite")
    // swiftlint:enable missing_docs
}
// swiftlint:enable identifier_name
