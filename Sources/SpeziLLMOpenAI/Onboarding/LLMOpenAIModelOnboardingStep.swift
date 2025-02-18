//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Spezi
import SpeziOnboarding
import SwiftUI


/// View to display an onboarding step for the user to enter change the OpenAI model.
public struct LLMOpenAIModelOnboardingStep: View {
    public enum Default {
        public static let models: [LLMOpenAIParameters.ModelType] = [
            .gpt3_5_turbo,
            .gpt4_turbo,
            .gpt4o,
            .o3_mini,
            .o3_mini_high,
            .o1,
            .o1_mini
        ]
    }
    
    
    @State private var modelSelection: LLMOpenAIParameters.ModelType
    private let actionText: String
    private let action: (LLMOpenAIParameters.ModelType) -> Void
    private let models: [LLMOpenAIParameters.ModelType]

    
    public var body: some View {
        OnboardingView(
            titleView: {
                OnboardingTitleView(
                    title: LocalizedStringResource("OPENAI_MODEL_SELECTION_TITLE", bundle: .atURL(from: .module)),
                    subtitle: LocalizedStringResource("OPENAI_MODEL_SELECTION_SUBTITLE", bundle: .atURL(from: .module))
                )
            },
            contentView: {
                Picker(
                    String(localized: "OPENAI_MODEL_SELECTION_DESCRIPTION", bundle: .module),
                    selection: $modelSelection
                ) {
                    ForEach(models, id: \.rawValue) { model in
                        Text(model.rawValue)
                            .tag(model)
                    }
                }
                    #if !os(macOS)
                    .pickerStyle(.wheel)
                    #else
                    .pickerStyle(PopUpButtonPickerStyle())
                    #endif
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
    ///   - action: Action that should be performed after the OpenAI model selection has been done, selection is passed as closure argument.
    public init(
        actionText: LocalizedStringResource? = nil,
        models: [LLMOpenAIParameters.ModelType] = Default.models,
        _ action: @escaping (LLMOpenAIParameters.ModelType) -> Void
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
        models: [LLMOpenAIParameters.ModelType] = Default.models,
        _ action: @escaping (LLMOpenAIParameters.ModelType) -> Void
    ) {
        self.actionText = String(actionText)
        self.models = models
        self.action = action
        _modelSelection = State(initialValue: models.first ?? .gpt3_5_turbo)
    }
}
