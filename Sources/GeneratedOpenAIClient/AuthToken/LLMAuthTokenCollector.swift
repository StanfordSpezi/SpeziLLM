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
/// The displayed text is fully configurable via init parameters using `LocalizedStringResource`, with sensible fallback defaults.
package struct LLMAuthTokenCollector: View {
    package struct CredentialsConfig: Sendable {
        public let tag: CredentialsTag
        public let username: String

        public init(tag: CredentialsTag, username: String) {
            self.tag = tag
            self.username = username
        }
    }

    @Environment(KeychainStorage.self) private var keychainStorage

    private let credentialsConfig: CredentialsConfig
    private let title: LocalizedStringResource
    private let subtitle: LocalizedStringResource
    private let prompt: LocalizedStringResource
    private let hint: LocalizedStringResource
    private let actionText: LocalizedStringResource
    private let action: @MainActor () async throws -> Void

    @State private var token: String = ""


    package var body: some View {
        OnboardingView(
            header: {
                OnboardingTitleView(
                    title: self.title
                )
            },
            content: {
                ScrollView {
                    VStack(spacing: 0) {
                        Text(self.subtitle)
                            .multilineTextAlignment(.center)
                        
                        TextField(
                            self.prompt.localizedString(),
                            text: $token
                        )
                        .frame(height: 50)
                        .textFieldStyle(.roundedBorder)
                        .padding(.vertical, 16)
                        
                        Text(
                            (try? AttributedString(
                                markdown: self.hint.localizedString()
                            )) ?? ""
                        )
                        .multilineTextAlignment(.center)
                        .font(.caption)
                    }
                }
            },
            footer: {
                OnboardingActionsView(
                    self.actionText,
                    action: {
                        try keychainStorage.store(
                            Credentials(
                                username: credentialsConfig.username,
                                password: token
                            ),
                            for: credentialsConfig.tag
                        )
                        try await action()
                    }
                )
                    .disabled(token.isEmpty)
            }
        )
            .task {
                if let stored = try? keychainStorage.retrieveCredentials(
                    withUsername: credentialsConfig.username,
                    for: credentialsConfig.tag
                )?.password {
                    token = stored
                }
            }
    }


    /// Create a new ``LLMAuthTokenCollector``.
    ///
    /// - Parameters:
    ///   - credentialsConfig: How to store the token.
    ///   - titleResource: Localized title. Defaults to `Defaults.title` if `nil`.
    ///   - subtitleResource: Localized subtitle. Defaults to `Defaults.subtitle` if `nil`.
    ///   - promptResource: Localized prompt. Defaults to `Defaults.prompt` if `nil`.
    ///   - hintResource: Localized hint (markdown). Defaults to `Defaults.hint` if `nil`.
    ///   - actionTextResource: Localized action button text. Defaults to `Defaults.action` if `nil`.
    ///   - action: Closure to run after storing.
    package init(
        credentialsConfig: CredentialsConfig,
        title: LocalizedStringResource? = nil,
        subtitle: LocalizedStringResource? = nil,
        prompt: LocalizedStringResource? = nil,
        hint: LocalizedStringResource? = nil,
        actionText: LocalizedStringResource? = nil,
        action: @escaping @MainActor () async throws -> Void
    ) {
        self.credentialsConfig = credentialsConfig
        self.title = title ?? Defaults.title
        self.subtitle = subtitle ?? Defaults.subtitle
        self.prompt = prompt ?? Defaults.prompt
        self.hint = hint ?? Defaults.hint
        self.actionText = actionText ?? Defaults.action
        self.action = action
    }
}

#if DEBUG
#Preview {
    LLMAuthTokenCollector(
        credentialsConfig: .init(
            tag: .genericPassword(forService: "openai.com"),
            username: "OpenAI.GPT"
        )
    ) {
        // completion
    }
        .previewWith {
            KeychainStorage()
        }
}
#endif
