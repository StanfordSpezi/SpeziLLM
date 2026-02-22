//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable file_types_order

import GeneratedOpenAIClient
import Spezi
import SpeziKeychainStorage
import SpeziOnboarding
import SwiftUI


/// View to display an onboarding step for the user to enter an OpenAI API Key.
///
/// - Warning: Ensure that the ``LLMOpenAIPlatform`` is specified within the Spezi `Configuration` when using this view in the onboarding flow.
///
/// - Important: Only use this if the corresponding LLM platform's config's auth token is set to `RemoteLLMInferenceAuthToken/keychain(_:CredentialsTag)`
public typealias LLMOpenAIAPITokenOnboardingStep = LLMOpenAILikeAPITokenOnboardingStep<OpenAIPlatformDefinition>


/// View to display an onboarding step for the user to enter an API key for an OpenAI-like platform.
///
/// - Warning: Ensure that the ``LLMOpenAIPlatform`` is specified within the Spezi `Configuration` when using this view in the onboarding flow.
///
/// - Important: Only use this if the corresponding LLM platform's config's auth token is set to `RemoteLLMInferenceAuthToken/keychain(_:CredentialsTag)`
public struct LLMOpenAILikeAPITokenOnboardingStep<PlatformDefinition: LLMOpenAILikePlatformDefinition>: View {
    private let actionText: LocalizedStringResource
    private let action: @MainActor () async throws -> Void

    @Environment(LLMOpenAILikePlatform<PlatformDefinition>.self) private var platform

    private var credentials: (tag: CredentialsTag, username: String) {
        switch platform.configuration.authToken {
        case let .keychain(tag, username):
            return (tag, username)
        case .none, .constant, .closure:
            fatalError(
                """
                Use of `\(Self.self)` without specifying the
                `\(LLMOpenAILikePlatformConfiguration<PlatformDefinition>.self).authToken` to `.keychain` is not supported.
                """
            )
        }
    }
    
    
    public var body: some View {
        LLMAuthTokenCollector(
            credentialsConfig: .init(
                tag: self.credentials.tag,
                username: self.credentials.username
            ),
            title: .init("\(PlatformDefinition.platformName) API Key", bundle: .atURL(from: .module)),
            subtitle: .init("Please enter your \(PlatformDefinition.platformName) API key", bundle: .atURL(from: .module)),
            prompt: .init("API Key…", bundle: .atURL(from: .module)),
            hint: { () -> LocalizedStringResource? in
                guard let url = PlatformDefinition.platformDeveloperConsoleUrl else {
                    return nil
                }
                return LocalizedStringResource(
                    "You can create and inspect your \(PlatformDefinition.platformName) API keys [in the API keys section of the \(PlatformDefinition.platformName) Website](\(url.absoluteString)).",
                    bundle: .module
                )
            }(),
            actionText: actionText
        ) {
            try await self.action()
        }
    }
    
    
    /// - Parameters:
    ///   - actionText: Localized text that should appear on the action button.
    ///   - action: Action that should be performed after the openAI API key has been persisted.
    public init(
        actionText: LocalizedStringResource? = nil,
        _ action: @escaping @MainActor () async throws -> Void
    ) {
        self.actionText = actionText ?? LocalizedStringResource("Continue", bundle: .module)
        self.action = action
    }
}


#if DEBUG
#Preview {
    LLMOpenAIAPITokenOnboardingStep(
        actionText: "Continue"
    ) {}
        .previewWith {
            LLMOpenAIPlatform(
                configuration: .init(authToken: .keychain(tag: .openAIKey, username: LLMOpenAIConstants.credentialsUsername))
            )
        }
}
#endif
