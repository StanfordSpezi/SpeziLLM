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


/// View to display an onboarding step for the user to enter an OpenAI API Key.
/// 
/// - Warning: Ensure that the ``LLMOpenAIPlatform`` is specified within the Spezi `Configuration` when using this view in the onboarding flow.
///
/// - Important: The ``LLMOpenAIAPITokenOnboardingStep`` can only be used with the auth token being set to `RemoteLLMInferenceAuthToken/keychain(_:CredentialsTag)`
public struct LLMOpenAIAPITokenOnboardingStep: View {
    private let actionText: String
    private let action: () -> Void

    @Environment(LLMOpenAIPlatform.self) private var openAiPlatform

    private var credentialsTag: CredentialsTag {
        guard case let .keychain(tag) = openAiPlatform.configuration.authToken else {
            fatalError(
            """
            Use of the `LLMOpenAIAPITokenOnboardingStep` without specifying the
            `LLMOpenAIPlatform.Configuration.authToken` to `.keychain` is not supported.
            """
            )
        }

        return tag
    }

    
    public var body: some View {
        LLMAuthTokenCollector(
            credentialsConfig: .init(
                tag: .openAIKey,
                username: LLMOpenAIConstants.credentialsUsername
            )
        ) {
            self.action()
        }
    }
    
    
    /// - Parameters:
    ///   - actionText: Localized text that should appear on the action button.
    ///   - action: Action that should be performed after the openAI API key has been persisted.
    public init(
        actionText: LocalizedStringResource? = nil,
        _ action: @escaping () -> Void
    ) {
        self.init(
            actionText: actionText?.localizedString() ?? String(localized: "OPENAI_API_KEY_SAVE_BUTTON", bundle: .module),
            action
        )
    }
    
    /// - Parameters:
    ///   - actionText: Text that should appear on the action button without localization.
    ///   - action: Action that should be performed after the openAI API key has been persisted.
    @_disfavoredOverload
    public init<ActionText: StringProtocol>(
        actionText: ActionText,
        _ action: @escaping () -> Void
    ) {
        self.actionText = String(actionText)
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
                configuration: .init(authToken: .keychain(.openAIKey))
            )
        }
}
#endif
