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
public struct LLMAuthTokenCollector: View {
    public struct CredentialsConfig: Sendable {
        public let tag: CredentialsTag
        public let username: String

        public init(tag: CredentialsTag, username: String) {
            self.tag = tag
            self.username = username
        }
    }

    @Environment(KeychainStorage.self) private var keychainStorage

    private let credentialsConfig: CredentialsConfig
    private let titleResource: LocalizedStringResource
    private let subtitleResource: LocalizedStringResource
    private let promptResource: LocalizedStringResource
    private let hintResource: LocalizedStringResource
    private let actionTextResource: LocalizedStringResource
    private let action: () async throws -> Void

    @State private var token: String = ""


    public var body: some View {
        OnboardingView(
            header: {
                OnboardingTitleView(
                    title: self.titleResource
                )
            },
            content: {
                ScrollView {
                    VStack(spacing: 0) {
                        Text(self.subtitleResource)
                            .multilineTextAlignment(.center)
                        
                        TextField(
                            self.promptResource.localizedString(),
                            text: $token
                        )
                        .frame(height: 50)
                        .textFieldStyle(.roundedBorder)
                        .padding(.vertical, 16)
                        
                        Text(
                            (try? AttributedString(
                                markdown: self.hintResource.localizedString()
                            )) ?? ""
                        )
                        .multilineTextAlignment(.center)
                        .font(.caption)
                    }
                }
            },
            footer: {
                OnboardingActionsView(
                    self.actionTextResource,
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
    ///   - titleResource: Localized title. Defaults to `Defaults.title`.
    ///   - subtitleResource: Localized subtitle. Defaults to `Defaults.subtitle`.
    ///   - promptResource: Localized prompt. Defaults to `Defaults.prompt`.
    ///   - hintResource: Localized hint (markdown). Defaults to `Defaults.hint`.
    ///   - actionTextResource: Localized action button text. Defaults to `Defaults.action`.
    ///   - action: Closure to run after storing.
    public init(
        credentialsConfig: CredentialsConfig,
        titleResource: LocalizedStringResource = Defaults.title,
        subtitleResource: LocalizedStringResource = Defaults.subtitle,
        promptResource: LocalizedStringResource = Defaults.prompt,
        hintResource: LocalizedStringResource = Defaults.hint,
        actionTextResource: LocalizedStringResource = Defaults.action,
        action: @escaping () async throws -> Void
    ) {
        self.credentialsConfig = credentialsConfig
        self.titleResource = titleResource
        self.subtitleResource = subtitleResource
        self.promptResource = promptResource
        self.hintResource = hintResource
        self.actionTextResource = actionTextResource
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
