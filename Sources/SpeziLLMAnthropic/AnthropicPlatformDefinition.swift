//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable file_types_order

import Foundation
import SpeziLLMOpenAI
import SpeziKeychainStorage


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
    public static let platformServiceIdentifier = "api.anthropic.com"
    
    public static let defaultServerUrl = URL(string: "https://api.anthropic.com/v1")! // swiftlint:disable:this force_unwrapping
    
    public static let platformDeveloperConsoleUrl = URL(string: "https://platform.claude.com/settings/keys")
}


// MARK: Type Specializations

/// Represents the configuration of the Spezi ``LLMAnthropicPlatform``.
public typealias LLMAnthropicPlatformConfiguration = LLMOpenAILikePlatformConfiguration<AnthropicPlatformDefinition>


/// Represents the parameters of an Anthropic LLM model.
public typealias LLMAnthropicParameters = LLMOpenAILikeParameters<AnthropicPlatformDefinition>


/// LLM execution platform of an Anthropic ``LLMAnthropicSchema``.
///
/// - Note: This type behaves identical to SpeziLLMOpenAI's `LLMOpenAIPlatform`, except that it interacts with Anthropic's APIs instead of OpenAI's; see the [`LLMOpenAIPlatform`](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillmopenai/llmopenaiplatform) documentation for further documentation.
///
/// ### Usage
///
/// The example below demonstrates the setup of the ``LLMAnthropicPlatform`` within the Spezi `Configuration`.
/// ```swift
/// class TestAppDelegate: SpeziAppDelegate {
///     override var configuration: Configuration {
///         Configuration {
///             LLMRunner {
///                 LLMAnthropicPlatform()
///             }
///         }
///     }
/// }
/// ```
public typealias LLMAnthropicPlatform = LLMOpenAILikePlatform<AnthropicPlatformDefinition>


/// Defines the type and configuration of the ``LLMAnthropicSession``.
///
/// The ``LLMAnthropicSchema`` is used as a configuration for the to-be-used LLMAnthropicPlatform LLM. It contains all information necessary for the creation of an executable ``LLMAnthropicSession``.
/// It is bound to a ``LLMAnthropicPlatform`` that is responsible for turning the ``LLMAnthropicSchema`` to an ``LLMAnthropicSession``.
///
/// - Note: This type behaves identical to SpeziLLMOpenAI's `LLMOpenAISchema`, except that it interacts with Anthropic's APIs instead of OpenAI's; see the [`LLMOpenAISchema`](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillmopenai/llmopenaischema) documentation for further documentation.
///
/// - Tip: ``LLMAnthropicSchema`` also enables the function calling mechanism to establish a structured, bidirectional, and reliable communication between the ``LLMAnthropicPlatform`` LLMs and external tools.
///     For more details, refer to the [`LLMOpenAISchema`](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillmopenai/llmopenaischema) documentation.
public typealias LLMAnthropicSchema = LLMOpenAILikeSchema<AnthropicPlatformDefinition>


/// Represents an ``LLMAnthropicSchema`` in execution.
///
/// The ``LLMAnthropicSession`` is the executable version of the LLMAnthropicPlatform LLM containing context and state as defined by the ``LLMAnthropicSchema``.
/// It provides access to text-based models from Anthropic, such as Claude Opus or Sonnet.
///
/// - Note: This type behaves identical to SpeziLLMOpenAI's `LLMAnthropicSession`, except that it interacts with Anthropic's APIs instead of OpenAI's; see the [`LLMOpenAISession`](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillmopenai/llmopenaisession) documentation for further documentation.
///
///
/// ### Usage
///
/// The example below demonstrates a minimal usage of the ``LLMAnthropicSession`` via the `LLMRunner`.
///
/// ```swift
/// import SpeziLLM
/// import SpeziLLMAnthropic
/// import SwiftUI
///
/// struct LLMAnthropicDemoView: View {
///     @Environment(LLMRunner.self) var runner
///     @State var responseText = ""
///
///     var body: some View {
///         Text(responseText)
///             .task {
///                 // Instantiate the `LLMAnthropicSchema` to an `LLMAnthropicSession` via the `LLMRunner`.
///                 let llmSession: LLMAnthropicSession = runner(
///                     with: LLMAnthropicSchema(
///                         parameters: .init(
///                             modelType: .opus4_6,
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
public typealias LLMAnthropicSession = LLMOpenAILikeSession<AnthropicPlatformDefinition>


/// View to display an onboarding step for the user to enter an Anthropic API Key.
///
/// - Warning: Ensure that the ``LLMAnthropicPlatformD`` is specified within the Spezi `Configuration` when using this view in the onboarding flow.
///
/// - Important: Only use this if the corresponding LLM platform's config's auth token is set to `RemoteLLMInferenceAuthToken/keychain(_:CredentialsTag)`
public typealias LLMAnthropicAPITokenOnboardingStep = LLMOpenAILikeAPITokenOnboardingStep<AnthropicPlatformDefinition>


/// View to display an onboarding step for the user to enter change the Anthropic model.
public typealias LLMAnthropicModelOnboardingStep = LLMOpenAILikeModelOnboardingStep<AnthropicPlatformDefinition>


extension CredentialsTag {
    public static let anthropicKey = Self.for(AnthropicPlatformDefinition.self)
}


// MARK: Models

// swiftlint:disable identifier_name
extension AnthropicPlatformDefinition.ModelType {
    /// The default model to be used with Anthropic.
    public static let `default`: Self = .opus4_6
    
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
