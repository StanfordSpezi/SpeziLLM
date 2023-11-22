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
    public enum Default {
        public static let models = [Model.gpt3_5Turbo, Model.gpt4]
    }
    
    fileprivate struct ModelSelection: Identifiable {
        fileprivate let id: String
        
        
        fileprivate var description: String {
            id.replacing("-", with: " ").capitalized.replacing("Gpt", with: "GPT")
        }
    }
    
    
    @Environment(OpenAIModel.self) private var openAI
    private let actionText: String
    private let action: () -> Void
    private let models: [ModelSelection]
    
    
    public var body: some View {
        OnboardingView(
            titleView: {
                OnboardingTitleView(
                    title: LocalizedStringResource("OPENAI_MODEL_SELECTION_TITLE", bundle: .atURL(from: .module)),
                    subtitle: LocalizedStringResource("OPENAI_MODEL_SELECTION_SUBTITLE", bundle: .atURL(from: .module))
                )
            },
            contentView: {
                @Bindable var openAI = openAI
                Picker(String(localized: "OPENAI_MODEL_SELECTION_DESCRIPTION", bundle: .module), selection: $openAI.openAIModel) {
                    ForEach(models) { model in
                        Text(model.description)
                            .tag(model.id)
                    }
                }
                    .pickerStyle(.wheel)
                    .accessibilityIdentifier("modelPicker")
            },
            actionView: {
                OnboardingActionsView(
                    verbatim: actionText,
                    action: {
                        action()
                    }
                )
            }
        )
    }
    
    /// - Parameters:
    ///   - actionText: Localized text that should appear on the action button.
    ///   - models: The models that should be displayed in the picker user interface.
    ///   - action: Action that should be performed after the openAI model selection has been persisted.
    public init(
        actionText: LocalizedStringResource? = nil,
        models: [Model] = Default.models,
        _ action: @escaping () -> Void
    ) {
        self.init(
            actionText: actionText?.localizedString() ?? String(localized: "OPENAI_MODEL_SELECTION_SAVE_BUTTON", bundle: .module),
            models: models,
            action
        )
    }
    
    /// - Parameters:
    ///   - actionText: Text that should appear on the action button without localization.
    ///   - models: The models that should be displayed in the picker user interface.
    ///   - action: Action that should be performed after the openAI model selection has been persisted.
    @_disfavoredOverload
    public init<ActionText: StringProtocol>(
        actionText: ActionText,
        models: [Model] = Default.models,
        _ action: @escaping () -> Void
    ) {
        self.actionText = String(actionText)
        self.models = models.map { ModelSelection(id: $0) }
        self.action = action
    }
}
