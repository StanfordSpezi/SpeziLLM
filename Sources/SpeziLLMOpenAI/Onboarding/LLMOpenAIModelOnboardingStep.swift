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
            .gpt5,
            .gpt5_mini,
            .gpt5_chat,
            .gpt4_1,
            .gpt4o,
            .o4_mini,
            .o3_pro,
            .o3,
            .o3_mini
        ]
    }
    
    
    @State private var selection: LLMOpenAIParameters.ModelType
    private let actionText: String
    private let models: [LLMOpenAIParameters.ModelType]
    private let action: @MainActor (LLMOpenAIParameters.ModelType) -> Void

    
    public var body: some View {
        OnboardingView(
            header: {
                OnboardingTitleView(
                    title: LocalizedStringResource("OPENAI_MODEL_SELECTION_TITLE", bundle: .atURL(from: .module)),
                    subtitle: LocalizedStringResource("OPENAI_MODEL_SELECTION_SUBTITLE", bundle: .atURL(from: .module))
                )
            },
            content: {
                Picker(
                    String(localized: "OPENAI_MODEL_SELECTION_DESCRIPTION", bundle: .module),
                    selection: $selection
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
            footer: {
                OnboardingActionsView(actionText) {
                    action(selection)
                }
            }
        )
    }
    
    /// - Parameters:
    ///   - actionText: Localized text that should appear on the action button.
    ///   - models: The models that should be displayed in the picker user interface.
    ///   - initial: The initial model which should be selected.
    ///   - action: Action that should be performed after the OpenAI model selection has been done, selection is passed as closure argument.
    public init(
        actionText: LocalizedStringResource? = nil,
        models: [LLMOpenAIParameters.ModelType] = Default.models,
        initial: LLMOpenAIParameters.ModelType? = nil,
        _ action: @escaping @MainActor (LLMOpenAIParameters.ModelType) -> Void
    ) {
        self.init(
            actionText: actionText?.localizedString() ?? String(localized: "OPENAI_MODEL_SELECTION_SAVE_BUTTON", bundle: .module),
            models: models,
            initial: initial,
            action
        )
    }
    
    /// - Parameters:
    ///   - actionText: Text that should appear on the action button without localization.
    ///   - models: The models that should be displayed in the picker user interface.
    ///   - initial: The initial model which should be selected.
    ///   - action: Action that should be performed after the OpenAI model selection has been done, selection is passed as closure argument.
    @_disfavoredOverload
    public init(
        actionText: some StringProtocol,
        models: [LLMOpenAIParameters.ModelType] = Default.models,
        initial: LLMOpenAIParameters.ModelType? = nil,
        _ action: @escaping @MainActor (LLMOpenAIParameters.ModelType) -> Void
    ) {
        self.actionText = String(actionText)
        self.models = models
        self.action = action
        _selection = State(initialValue: initial ?? models.first ?? .gpt3_5_turbo)
    }
}
