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
import SpeziKeychainStorage


/// The OpenAI platform's definition.
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
    public static let platformServiceIdentifier = "api.openai.com"
    
    public static let platformDeveloperConsoleUrl = URL(string: "https://platform.openai.com/account/api-keys")
    
    public static let defaultServerUrl: URL = {
        guard let url = try? Servers.Server1.url() else {
            fatalError("The default OpenAI API endpoint couldn't be extracted from the OpenAI OpenAPI document.")
        }
        return url
    }()
}


// MARK: Type Specializations

/// Represents the configuration of the Spezi ``LLMOpenAIPlatform``.
public typealias LLMOpenAIPlatformConfiguration = LLMOpenAILikePlatformConfiguration<OpenAIPlatformDefinition>


/// Represents the parameters of an OpenAI LLM model.
public typealias LLMOpenAIParameters = LLMOpenAILikeParameters<OpenAIPlatformDefinition>


/// LLM execution platform of an ``LLMOpenAISchema``.
///
/// The ``LLMOpenAIPlatform`` turns a received ``LLMOpenAISchema`` to an executable ``LLMOpenAISession``.
/// Use ``LLMOpenAILikePlatform/callAsFunction(with:)`` with an ``LLMOpenAISchema`` parameter to get an executable ``LLMOpenAISession`` that does the actual inference.
///
/// The platform can be configured with the ``LLMOpenAIPlatformConfiguration``, enabling developers to specify properties like a custom server `URL`s, API tokens, the retry policy or timeouts.
///
/// - Important: ``LLMOpenAIPlatform`` shouldn't be used directly but used via the `SpeziLLM` `LLMRunner` that delegates the requests towards the ``LLMOpenAIPlatform``.
/// The `SpeziLLM` `LLMRunner` must be configured with the ``LLMOpenAIPlatform`` within the Spezi `Configuration`.
///
/// - Tip: For more information, refer to the documentation of the `LLMPlatform` from SpeziLLM.
///
/// ### Usage
///
/// The example below demonstrates the setup of the ``LLMOpenAIPlatform`` within the Spezi `Configuration`.
///
/// ```swift
/// class TestAppDelegate: SpeziAppDelegate {
///     override var configuration: Configuration {
///         Configuration {
///             LLMRunner {
///                 LLMOpenAIPlatform()
///             }
///         }
///     }
/// }
/// ```
public typealias LLMOpenAIPlatform = LLMOpenAILikePlatform<OpenAIPlatformDefinition>


/// Defines the type and configuration of the ``LLMOpenAISession``.
///
/// The ``LLMOpenAISchema`` is used as a configuration for the to-be-used OpenAI LLM. It contains all information necessary for the creation of an executable ``LLMOpenAISession``.
/// It is bound to a ``LLMOpenAIPlatform`` that is responsible for turning the ``LLMOpenAISchema`` to an ``LLMOpenAISession``.
///
/// - Tip: ``LLMOpenAISchema`` also enables the function calling mechanism to establish a structured, bidirectional, and reliable communication between the OpenAI LLMs and external tools. For details, refer to ``LLMFunction`` and ``LLMFunction/Parameter`` or the <doc:FunctionCalling> DocC article.
///
/// - Tip: For more information, refer to the documentation of the `LLMSchema` from SpeziLLM.
public typealias LLMOpenAISchema = LLMOpenAILikeSchema<OpenAIPlatformDefinition>


/// Represents an ``LLMOpenAISchema`` in execution.
///
/// The ``LLMOpenAISession`` is the executable version of the OpenAI LLM containing context and state as defined by the ``LLMOpenAISchema``.
/// It provides access to text-based models from OpenAI, such as GPT-3.5 or GPT-4.
///
/// The inference is started by ``LLMOpenAILikeSession/generate()``, returning an `AsyncThrowingStream` and can be cancelled via ``LLMOpenAILikeSession/cancel()``.
/// The ``LLMOpenAISession`` exposes its current state via the ``LLMOpenAILikeSession/context`` property, containing all the conversational history with the LLM.
///
/// - Warning: The ``LLMOpenAISession`` shouldn't be created manually but always through the ``LLMOpenAIPlatform`` via the `LLMRunner`.
///
/// - Tip: ``LLMOpenAISession`` also enables the function calling mechanism to establish a structured, bidirectional, and reliable communication between the OpenAI LLMs and external tools. For details, refer to ``LLMFunction`` and ``LLMFunction/Parameter`` or the <doc:FunctionCalling> DocC article.
///
/// - Tip: For more information, refer to the documentation of the `LLMSession` from SpeziLLM.
///
/// ### Usage
///
/// The example below demonstrates a minimal usage of the ``LLMOpenAISession`` via the `LLMRunner`.
///
/// ```swift
/// import SpeziLLM
/// import SpeziLLMOpenAI
/// import SwiftUI
///
/// struct LLMOpenAIDemoView: View {
///     @Environment(LLMRunner.self) var runner
///     @State var responseText = ""
///
///     var body: some View {
///         Text(responseText)
///             .task {
///                 // Instantiate the `LLMOpenAISchema` to an `LLMOpenAISession` via the `LLMRunner`.
///                 let llmSession: LLMOpenAISession = runner(
///                     with: LLMOpenAISchema(
///                         parameters: .init(
///                             modelType: .gpt4o,
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
public typealias LLMOpenAISession = LLMOpenAILikeSession<OpenAIPlatformDefinition>


/// View to display an onboarding step for the user to enter an OpenAI API Key.
///
/// - Warning: Ensure that the ``LLMOpenAIPlatform`` is specified within the Spezi `Configuration` when using this view in the onboarding flow.
///
/// - Important: Only use this if the corresponding LLM platform's config's auth token is set to `RemoteLLMInferenceAuthToken/keychain(_:CredentialsTag)`
public typealias LLMOpenAIAPITokenOnboardingStep = LLMOpenAILikeAPITokenOnboardingStep<OpenAIPlatformDefinition>


/// View to display an onboarding step for the user to enter change the OpenAI model.
public typealias LLMOpenAIModelOnboardingStep = LLMOpenAILikeModelOnboardingStep<OpenAIPlatformDefinition>


extension CredentialsTag {
    public static let openAIKey = Self.for(OpenAIPlatformDefinition.self)
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
