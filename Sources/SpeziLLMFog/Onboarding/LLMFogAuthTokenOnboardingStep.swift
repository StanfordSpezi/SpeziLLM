//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import GeneratedOpenAIClient
import Spezi
import SpeziKeychainStorage
import SpeziOnboarding
import SwiftUI


/// View to display an onboarding step for the user to enter an fog auth token.
/// 
/// - Warning: Ensure that the ``LLMFogPlatform`` is specified within the Spezi `Configuration` when using this view in the onboarding flow.
///
/// - Important: The ``LLMFogAuthTokenOnboardingStep`` can only be used with the auth token being set to `RemoteLLMInferenceAuthToken/keychain(_:CredentialsTag)`.
public struct LLMFogAuthTokenOnboardingStep: View {
    private let actionText: String
    private let action: () async throws -> Void

    @Environment(LLMFogPlatform.self) private var fogPlatform

    private var credentialsTag: CredentialsTag {
        guard case let .keychain(tag) = fogPlatform.configuration.authToken else {
            fatalError(
            """
            Use of the `LLMFogAuthTokenOnboardingStep` without specifying the
            `LLMFogPlatform.Configuration.authToken` to `.keychain` is not supported.
            """
            )
        }

        return tag
    }

    
    public var body: some View {
        LLMAuthTokenCollector(
            credentialsConfig: .init(
                tag: self.credentialsTag,
                username: LLMFogConstants.credentialsUsername
            ),
            titleResource: .init("LLM_AUTH_TOKEN_ONBOARDING_TITLE", bundle: .atURL(from: .module)),
            subtitleResource: .init("LLM_AUTH_TOKEN_ONBOARDING_SUBTITLE", bundle: .atURL(from: .module)),
            promptResource: .init("LLM_AUTH_TOKEN_ONBOARDING_PROMPT", bundle: .atURL(from: .module)),
            hintResource: .init("LLM_AUTH_TOKEN_ONBOARDING_HINT", bundle: .atURL(from: .module)),
            actionTextResource: .init("LLM_AUTH_TOKEN_ONBOARDING_ACTION_TEXT", bundle: .atURL(from: .module))
        ) {
            try await self.action()
        }
    }
    
    
    /// - Parameters:
    ///   - actionText: Localized text that should appear on the action button.
    ///   - action: Action that should be performed after the openAI API key has been persisted.
    public init(
        actionText: LocalizedStringResource? = nil,
        _ action: @escaping () async throws -> Void
    ) {
        self.init(
            actionText: actionText?.localizedString() ?? String(localized: "FOG_API_KEY_SAVE_BUTTON", bundle: .module),
            action
        )
    }
    
    /// - Parameters:
    ///   - actionText: Text that should appear on the action button without localization.
    ///   - action: Action that should be performed after the openAI API key has been persisted.
    @_disfavoredOverload
    public init<ActionText: StringProtocol>(
        actionText: ActionText,
        _ action: @escaping () async throws -> Void
    ) {
        self.actionText = String(actionText)
        self.action = action
    }
}


#if DEBUG
#Preview {
    LLMFogAuthTokenOnboardingStep(
        actionText: "Continue"
    ) {}
        .previewWith {
            LLMFogPlatform(
                configuration: .init(connectionType: .http, authToken: .keychain(.fogAuthToken))
            )
        }
}
#endif
