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
public struct LLMOpenAIModelOnboardingStep: View {
    public enum Default {
        public static let models = [Model.gpt3_5Turbo, Model.gpt4]
    }
    
    
    @State private var modelSelection: Model
    private let actionText: String
    private let action: (Model) -> Void
    private let models: [Model]
    
    
    public var body: some View {
        OnboardingView(
            titleView: {
                OnboardingTitleView(
                    title: LocalizedStringResource("OPENAI_MODEL_SELECTION_TITLE", bundle: .atURL(from: .module)),
                    subtitle: LocalizedStringResource("OPENAI_MODEL_SELECTION_SUBTITLE", bundle: .atURL(from: .module))
                )
            },
            contentView: {
                Picker(String(localized: "OPENAI_MODEL_SELECTION_DESCRIPTION", bundle: .module), selection: $modelSelection) {
                    ForEach(models, id: \.self) { model in
                        Text(model.formattedModelDescription)
                            .tag(model.formattedModelDescription)
                    }
                }
                    .pickerStyle(.wheel)
                    .accessibilityIdentifier("modelPicker")
            },
            actionView: {
                OnboardingActionsView(
                    verbatim: actionText,
                    action: {
                        action(modelSelection)
                    }
                )
            }
        )
    }
    
    /// - Parameters:
    ///   - actionText: Localized text that should appear on the action button.
    ///   - models: The models that should be displayed in the picker user interface.
    ///   - action: Action that should be performed after the openAI model selection has been done, selection is passed as closure argument.
    public init(
        actionText: LocalizedStringResource? = nil,
        models: [Model] = Default.models,
        _ action: @escaping (Model) -> Void
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
    ///   - action: Action that should be performed after the OpenAI model selection has been done, selection is passed as closure argument.
    @_disfavoredOverload
    public init<ActionText: StringProtocol>(
        actionText: ActionText,
        models: [Model] = Default.models,
        _ action: @escaping (Model) -> Void
    ) {
        self.actionText = String(actionText)
        self.models = models
        self.action = action
        self._modelSelection = State(initialValue: models.first ?? .gpt3_5Turbo_1106)
    }
}


private extension Model {   // swiftlint:disable:this no_extension_access_modifier
    var formattedModelDescription: String {
        self.replacing("-", with: " ").capitalized.replacing("Gpt", with: "GPT")
    }
}
