//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Spezi
import SpeziKeychainStorage
import SpeziOnboarding
import SwiftUI


/// `View` for the user to enter an auth token for remote LLM inference.
///
/// - Warning: Ensure that the `KeychainStorage` is present in the `Environment` by either specifying it directly within the  Spezi `Configuration` or a `Module` that depends on it, like the `SpeziLLMOpenAIPlatform` or the `SpeziLLMFogPlatform`.
public struct LLMAuthTokenCollector: View {
    /// Configuration of how the auth token for remote LLM inference should be stored in the secure enclave.
    public struct CredentialsConfig: Sendable {
        /// The tag defining how and where the credentials should be stored.
        public let tag: CredentialsTag
        /// The username of the to-be-stored credentials pair.
        public let username: String
    }

    @Environment(KeychainStorage.self) private var keychainStorage

    private let credentialsConfig: CredentialsConfig
    private let actionText: String
    private let action: () -> Void

    @State private var token: String = ""


    public var body: some View {
        OnboardingView(
            titleView: {
                OnboardingTitleView(
                    title: String(localized: "LLM_AUTH_TOKEN_COLLECTOR_TITLE", bundle: .module)
                )
            },
            contentView: {
                ScrollView {
                    VStack(spacing: 0) {
                        Text(String(localized: "LLM_AUTH_TOKEN_COLLECTOR_SUBTITLE", bundle: .module))
                            .multilineTextAlignment(.center)

                        TextField(String(localized: "LLM_AUTH_TOKEN_COLLECTOR_PROMPT", bundle: .module), text: $token)
                            .frame(height: 50)
                            .textFieldStyle(.roundedBorder)
                            .padding(.vertical, 16)

                        Text((try? AttributedString(
                            markdown: String(
                                localized: "LLM_AUTH_TOKEN_COLLECTOR_SUBTITLE_HINT",
                                bundle: .module
                            )
                        )) ?? "")
                            .multilineTextAlignment(.center)
                            .font(.caption)
                    }
                }
            },
            actionView: {
                OnboardingActionsView(
                    verbatim: actionText,
                    action: {
                        // Store token in secure enclave
                        try keychainStorage.store(
                            Credentials(username: self.credentialsConfig.username, password: token),
                            for: self.credentialsConfig.tag
                        )

                        action()
                    }
                )
                    .disabled(self.token.isEmpty)
            }
        )
            // Read potentially existing token from secure enclave
            .task {
                guard let token = try? keychainStorage.retrieveCredentials(
                    withUsername: self.credentialsConfig.username,
                    for: self.credentialsConfig.tag
                )?.password else {
                    return
                }

                self.token = token
            }
    }


    /// - Parameters:
    ///   - credentialsConfig: Configuration of how the captured credentials should be stored.
    ///   - actionText: Localized text that should appear on the action button.
    ///   - action: Action that should be performed after the openAI API key has been persisted.
    public init(
        credentialsConfig: CredentialsConfig,
        actionText: LocalizedStringResource? = nil,
        _ action: @escaping () -> Void
    ) {
        self.init(
            credentialsConfig: credentialsConfig,
            actionText: actionText?.localizedString() ?? String(localized: "LLM_AUTH_TOKEN_COLLECTOR_SAVE_BUTTON", bundle: .module),
            action
        )
    }

    /// - Parameters:
    ///   - credentialsConfig: Configuration of how the captured credentials should be stored.
    ///   - actionText: Text that should appear on the action button without localization.
    ///   - action: Action that should be performed after the openAI API key has been persisted.
    @_disfavoredOverload
    public init<ActionText: StringProtocol>(
        credentialsConfig: CredentialsConfig,
        actionText: ActionText,
        _ action: @escaping () -> Void
    ) {
        self.credentialsConfig = credentialsConfig
        self.actionText = String(actionText)
        self.action = action
    }
}
