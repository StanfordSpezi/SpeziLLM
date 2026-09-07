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
    public static let `default`: Self = .gpt5_6

    /// The list of currently supported, non-deprecated models shown in model pickers.
    ///
    /// Models that OpenAI has retired or scheduled for shutdown are intentionally excluded here; they remain
    /// available as deprecated constants further below for source compatibility.
    public static let wellKnownModels: [Self] = [
        .gpt6_astra,
        .gpt5_6, .gpt5_6_sol, .gpt5_6_terra, .gpt5_6_luna,
        .gpt5_5, .gpt5_5_pro,
        .gpt5_4, .gpt5_4_pro, .gpt5_4_mini, .gpt5_4_nano,
        .gpt4o, .gpt4o_mini,
        .gpt4_1, .gpt4_1_mini
    ]

    // GPT-6 series
    public static let gpt6_astra = Self(rawValue: "gpt-6-astra")

    // GPT-5.6 series (alias `gpt-5.6` routes to `gpt-5.6-sol`)
    public static let gpt5_6 = Self(rawValue: "gpt-5.6")
    public static let gpt5_6_sol = Self(rawValue: "gpt-5.6-sol")
    public static let gpt5_6_terra = Self(rawValue: "gpt-5.6-terra")
    public static let gpt5_6_luna = Self(rawValue: "gpt-5.6-luna")

    // GPT-5.5 series
    public static let gpt5_5 = Self(rawValue: "gpt-5.5")
    public static let gpt5_5_pro = Self(rawValue: "gpt-5.5-pro")

    // GPT-5.4 series
    public static let gpt5_4 = Self(rawValue: "gpt-5.4")
    public static let gpt5_4_pro = Self(rawValue: "gpt-5.4-pro")
    public static let gpt5_4_mini = Self(rawValue: "gpt-5.4-mini")
    public static let gpt5_4_nano = Self(rawValue: "gpt-5.4-nano")

    // GPT-4 series
    public static let gpt4o = Self(rawValue: "gpt-4o")
    public static let gpt4o_mini = Self(rawValue: "gpt-4o-mini")
    public static let gpt4_1 = Self(rawValue: "gpt-4.1")
    public static let gpt4_1_mini = Self(rawValue: "gpt-4.1-mini")

    // MARK: Deprecated & retired models
    //
    // OpenAI has retired these models or scheduled them for shutdown. They are kept here (and excluded from
    // `wellKnownModels`) so existing code keeps compiling, but new code should use the suggested replacement.
    // Reference: https://developers.openai.com/api/docs/deprecations

    @available(*, deprecated, message: "OpenAI retired gpt-5-chat-latest on 2026-07-23; use `.gpt5_6_sol`.")
    public static let gpt5_chat = Self(rawValue: "gpt-5-chat-latest")

    @available(*, deprecated, message: "OpenAI shuts down gpt-5 on 2026-12-11; use `.gpt5_6_sol`.")
    public static let gpt5 = Self(rawValue: "gpt-5")

    @available(*, deprecated, message: "OpenAI shuts down gpt-5-mini on 2026-12-11; use `.gpt5_6_terra`.")
    public static let gpt5_mini = Self(rawValue: "gpt-5-mini")

    @available(*, deprecated, message: "OpenAI shuts down gpt-5-nano on 2026-12-11; use `.gpt5_6_luna`.")
    public static let gpt5_nano = Self(rawValue: "gpt-5-nano")

    @available(*, deprecated, message: "OpenAI shuts down gpt-4-turbo on 2026-10-23; use `.gpt5_6_sol`.")
    public static let gpt4_turbo = Self(rawValue: "gpt-4-turbo")

    @available(*, deprecated, message: "OpenAI shuts down gpt-4.1-nano on 2026-10-23; use `.gpt5_6_luna`.")
    public static let gpt4_1_nano = Self(rawValue: "gpt-4.1-nano")

    @available(*, deprecated, message: "OpenAI shuts down o4-mini on 2026-10-23; use `.gpt5_6_terra`.")
    public static let o4_mini = Self(rawValue: "o4-mini")

    @available(*, deprecated, message: "OpenAI shuts down o3 on 2026-12-11; use `.gpt5_6_sol`.")
    public static let o3 = Self(rawValue: "o3")

    @available(*, deprecated, message: "OpenAI shuts down o3-pro on 2026-12-11; use `.gpt5_6_sol`.")
    public static let o3_pro = Self(rawValue: "o3-pro")

    @available(*, deprecated, message: "OpenAI shuts down o3-mini on 2026-10-23; use `.gpt5_6_sol`.")
    public static let o3_mini = Self(rawValue: "o3-mini")

    @available(*, deprecated, message: "o3-mini-high is not a valid API model id (ChatGPT-only label); use `.o3_mini`.")
    public static let o3_mini_high = Self(rawValue: "o3-mini-high")

    @available(*, deprecated, message: "OpenAI shuts down o1-pro on 2026-10-23; use `.gpt5_6_sol`.")
    public static let o1_pro = Self(rawValue: "o1-pro")

    @available(*, deprecated, message: "OpenAI shuts down o1 on 2026-10-23; use `.gpt5_6_sol`.")
    public static let o1 = Self(rawValue: "o1")

    @available(*, deprecated, message: "OpenAI retired o1-mini on 2025-10-27; use `.gpt5_6_terra`.")
    public static let o1_mini = Self(rawValue: "o1-mini")

    @available(*, deprecated, message: "OpenAI shuts down the gpt-3.5-turbo snapshots by 2026-10-23; use `.gpt5_6_terra`.")
    public static let gpt3_5_turbo = Self(rawValue: "gpt-3.5-turbo")

    public var acceptsSamplingParameters: Bool {
        // The reasoning models answer a sampling parameter with a `400` instead of applying it, and every current
        // family — the o-series, GPT-5.x and GPT-6 — reasons. `gpt-5-chat-latest` was the non-reasoning chat
        // variant of its family and kept them.
        guard rawValue != "gpt-5-chat-latest" else {
            return true
        }
        return !["o1", "o3", "o4", "gpt-5", "gpt-6"].contains { rawValue.hasPrefix($0) }
    }
}
