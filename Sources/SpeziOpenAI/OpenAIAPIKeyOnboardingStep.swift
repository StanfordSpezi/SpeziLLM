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
public struct OpenAIAPIKeyOnboardingStep<ComponentStandard: Standard>: View {
    @EnvironmentObject private var openAI: OpenAIComponent<ComponentStandard>
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
                    VStack {
                        Text(String(localized: "OPENAI_API_KEY_SUBTITLE", bundle: .module))
                            .multilineTextAlignment(.center)
                        Text((try? AttributedString(
                            markdown: String(
                                localized: "OPENAI_API_KEY_SUBTITLE_HINT",
                                bundle: .module
                            )
                        )) ?? "")
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 16)
                        TextField(String(localized: "OPENAI_API_KEY_PROMT", bundle: .module), text: apiToken)
                            .frame(height: 50)
                            .padding(.vertical)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            },
            actionView: {
                OnboardingActionsView(
                    String(localized: "OPENAI_API_KEY_SAVE_BUTTON", bundle: .module),
                    action: {
                        action()
                    }
                )
                    .disabled(apiToken.wrappedValue.isEmpty)
            }
        )
    }
    
    
    public init(_ action: @escaping () -> Void) {
        self.action = action
    }
}
