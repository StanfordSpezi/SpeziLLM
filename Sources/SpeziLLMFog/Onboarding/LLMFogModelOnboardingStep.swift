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


/// View to display an onboarding step for the user to enter the to-be-used fog model.
public struct LLMFogModelOnboardingStep: View {
    public enum Default {
        public static let models: [LLMFogParameters.FogModelType] = [
            .llama3_1_8B,
            .llama3_2,
            .phi4,
            .gemma_7B,
            .deepSeekR1
        ]
    }
    
    
    @State private var modelSelection: LLMFogParameters.FogModelType
    private let actionText: String
    private let action: (LLMFogParameters.FogModelType) -> Void
    private let models: [LLMFogParameters.FogModelType]

    
    public var body: some View {
        OnboardingView(
            header: {
                OnboardingTitleView(
                    title: LocalizedStringResource("FOG_MODEL_SELECTION_TITLE", bundle: .atURL(from: .module)),
                    subtitle: LocalizedStringResource("FOG_MODEL_SELECTION_SUBTITLE", bundle: .atURL(from: .module))
                )
            },
            content: {
                Picker(
                    String(localized: "FOG_MODEL_SELECTION_DESCRIPTION", bundle: .module),
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
            footer: {
                OnboardingActionsView(
                    actionText,
                    action: {
                        action(modelSelection)
                    }
                )
            }
        )
    }

    /// Creates a fog model picker with an action button.
    ///
    /// - Parameters:
    ///   - actionText: Localized text that should appear on the action button.
    ///   - models: The models that should be displayed in the picker user interface.
    ///   - action: Action that should be performed after the fog model selection has been done, selection is passed as closure argument.
    public init(
        actionText: LocalizedStringResource? = nil,
        models: [LLMFogParameters.FogModelType] = Default.models,
        _ action: @escaping (LLMFogParameters.FogModelType) -> Void
    ) {
        self.init(
            actionText: actionText?.localizedString() ?? String(localized: "FOG_MODEL_SELECTION_SAVE_BUTTON", bundle: .module),
            models: models,
            action
        )
    }

    /// Creates a fog model picker with an action button.
    /// 
    /// - Parameters:
    ///   - actionText: Text that should appear on the action button without localization.
    ///   - models: The models that should be displayed in the picker user interface.
    ///   - action: Action that should be performed after the fog model selection has been done, selection is passed as closure argument.
    @_disfavoredOverload
    public init<ActionText: StringProtocol>(
        actionText: ActionText,
        models: [LLMFogParameters.FogModelType] = Default.models,
        _ action: @escaping (LLMFogParameters.FogModelType) -> Void
    ) {
        self.actionText = String(actionText)
        self.models = models
        self.action = action
        self._modelSelection = State(initialValue: models.first ?? .llama3_1_8B)
    }
}
