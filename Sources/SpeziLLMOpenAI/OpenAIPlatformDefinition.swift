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
        public let modelId: String
        public let apiMode: LLMOpenAIAPIMode
        
        public init(modelId: String, apiMode: LLMOpenAIAPIMode) {
            self.modelId = modelId
            self.apiMode = apiMode
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
public typealias LLMOpenAISession = LLMOpenAILikeSession<OpenAIPlatformDefinition>


/// View to display an onboarding step for the user to enter an OpenAI API Key.
///
/// - Warning: Ensure that the ``LLMOpenAIPlatform`` is specified within the Spezi `Configuration` when using this view in the onboarding flow.
///
/// - Important: Only use this if the corresponding LLM platform's config's auth token is set to `RemoteLLMInferenceAuthToken/keychain(_:CredentialsTag)`
public typealias LLMOpenAIAPITokenOnboardingStep = LLMOpenAILikeAPITokenOnboardingStep<OpenAIPlatformDefinition>


/// View to display an onboarding step for the user to select an OpenAI model.
public typealias LLMOpenAIModelOnboardingStep = LLMOpenAILikeModelOnboardingStep<OpenAIPlatformDefinition>


extension CredentialsTag {
    /// The canonical credentials tag for the OpenAI API key
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

    /// Models that use the legacy Chat Completions API.
    /// All other OpenAI models (including custom model strings) default to the Responses API.
    private static let chatCompletionModels: Set<String> = [
        "gpt-4o", "gpt-4o-mini",
        "gpt-4-turbo",
        "gpt-3.5-turbo"
    ]

    // GPT-5 series
    public static let gpt5 = Self(modelId: "gpt-5", apiMode: .responses)
    public static let gpt5_mini = Self(modelId: "gpt-5-mini", apiMode: .responses)
    public static let gpt5_nano = Self(modelId: "gpt-5-nano", apiMode: .responses)
    public static let gpt5_chat = Self(modelId: "gpt-5-chat-latest", apiMode: .responses)
    public static let gpt5_pro = Self(modelId: "gpt-5-pro", apiMode: .responses)
    
    public static let gpt5_4 = Self(modelId: "gpt-5.4", apiMode: .responses)
    public static let gpt5_4_pro = Self(modelId: "gpt-5.4-pro", apiMode: .responses)
    public static let gpt5_5 = Self(modelId: "gpt-5.5", apiMode: .responses)
    public static let gpt5_5_pro = Self(modelId: "gpt-5.5-pro", apiMode: .responses)

    // GPT-4 series
    public static let gpt4o = Self(modelId: "gpt-4o", apiMode: .chatCompletions)
    public static let gpt4o_mini = Self(modelId: "gpt-4o-mini", apiMode: .chatCompletions)
    public static let gpt4_turbo = Self(modelId: "gpt-4-turbo", apiMode: .chatCompletions)
    public static let gpt4_1 = Self(modelId: "gpt-4.1", apiMode: .responses)
    public static let gpt4_1_mini = Self(modelId: "gpt-4.1-mini", apiMode: .responses)
    public static let gpt4_1_nano = Self(modelId: "gpt-4.1-nano", apiMode: .responses)

    // o-series
    public static let o4_mini = Self(modelId: "o4-mini", apiMode: .responses)
    public static let o3 = Self(modelId: "o3", apiMode: .responses)
    public static let o3_pro = Self(modelId: "o3-pro", apiMode: .responses)
    public static let o3_mini = Self(modelId: "o3-mini", apiMode: .responses)
    public static let o3_mini_high = Self(modelId: "o3-mini-high", apiMode: .responses)
    public static let o1_pro = Self(modelId: "o1-pro", apiMode: .responses)
    public static let o1 = Self(modelId: "o1", apiMode: .responses)
    public static let o1_mini = Self(modelId: "o1-mini", apiMode: .responses)

    // Others
    public static let gpt3_5_turbo = Self(modelId: "gpt-3.5-turbo", apiMode: .chatCompletions)
    
    
    public var supportsReasoningSummary: Bool {
        guard apiMode == .responses else {
            return false
        }
        // The o-series and GPT-5 reasoning variants emit reasoning summaries.
        // `gpt-5-chat-latest` is the non-reasoning chat variant and is excluded.
        if modelId == "gpt-5-chat-latest" {
            return false
        }
        return modelId.hasPrefix("o1")
            || modelId.hasPrefix("o3")
            || modelId.hasPrefix("o4")
            || modelId.hasPrefix("gpt-5")
    }
}
