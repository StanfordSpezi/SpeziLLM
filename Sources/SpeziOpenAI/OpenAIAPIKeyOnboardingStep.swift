//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import OpenAI
import Spezi
import SpeziOnboarding
import SwiftUI


/// View to display an onboarding step for the user to enter an OpenAI API Key.
public struct OpenAIAPIKeyOnboardingStep: View {
    @Environment(OpenAIModel.self) private var openAI
    private let actionText: String
    private let action: () -> Void
    
    
    private var apiToken: Binding<String> {
        Binding(
            get: {
                openAI.apiToken ?? ""
            },
            set: { newValue in
                guard !newValue.isEmpty else {
                    openAI.apiToken = nil
                    return
                }
                
                openAI.apiToken = newValue
            }
        )
    }
    
    public var body: some View {
        OnboardingView(
            titleView: {
                OnboardingTitleView(
                    title: String(localized: "OPENAI_API_KEY_TITLE", bundle: .module)
                )
            },
            contentView: {
                ScrollView {
                    VStack(spacing: 0) {
                        Text(String(localized: "OPENAI_API_KEY_SUBTITLE", bundle: .module))
                            .multilineTextAlignment(.center)
                        TextField(String(localized: "OPENAI_API_KEY_PROMPT", bundle: .module), text: apiToken)
                            .frame(height: 50)
                            .textFieldStyle(.roundedBorder)
                            .padding(.vertical, 16)
                        Text((try? AttributedString(
                            markdown: String(
                                localized: "OPENAI_API_KEY_SUBTITLE_HINT",
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
                        action()
                    }
                )
                    .disabled(apiToken.wrappedValue.isEmpty)
            }
        )
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
