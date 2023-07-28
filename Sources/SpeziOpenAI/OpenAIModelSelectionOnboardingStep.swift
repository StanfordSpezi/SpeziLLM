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


/// View to display an onboarding step for the user to enter change the OpenAI model.
public struct OpenAIModelSelectionOnboardingStep: View {
    @EnvironmentObject private var openAI: OpenAIComponent
    private let actionText: String
    private let action: () -> Void
    
    
    public var body: some View {
        OnboardingView(
            titleView: {
                OnboardingTitleView(
                    title: String(localized: "OPENAI_MODEL_SELECTION_TITLE", bundle: .module),
                    subtitle: String(localized: "OPENAI_MODEL_SELECTION_SUBTITLE", bundle: .module)
                )
            },
            contentView: {
                Picker(String(localized: "OPENAI_MODEL_SELECTION_DESCRIPTION", bundle: .module), selection: $openAI.openAIModel) {
                    Text("GPT 3.5 Turbo")
                        .tag(Model.gpt3_5Turbo)
                    Text("GPT 4")
                        .tag(Model.gpt4)
                }
                    .pickerStyle(.wheel)
                    .accessibilityIdentifier("modelPicker")
            },
            actionView: {
                OnboardingActionsView(
                    actionText,
                    action: {
                        action()
                    }
                )
            }
        )
    }
    
    
    /// - Parameters:
    ///   - actionText: Text that should appear on the action button.
    ///   - action: Action that should be performed after the openAI model selection has been persisted.
    public init(
        actionText: String? = nil,
        _ action: @escaping () -> Void
    ) {
        self.actionText = actionText ?? String(localized: "OPENAI_MODEL_SELECTION_SAVE_BUTTON", bundle: .module)
        self.action = action
    }
}
