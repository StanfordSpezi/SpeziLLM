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


/// View to display an onboarding step for the user to select an OpenAI-like model.
public struct LLMOpenAILikeModelOnboardingStep<PlatformDefinition: LLMOpenAILikePlatformDefinition>: View {
    @Environment(\.colorScheme) private var colorScheme
    
    private let primaryActionTitle: Text
    private let models: [PlatformDefinition.ModelType]
    // why is this a closure instead of passing in a binding?
    private let action: @MainActor (PlatformDefinition.ModelType) -> Void
    
    @State private var selection: PlatformDefinition.ModelType
    
    public var body: some View {
        OnboardingView {
            OnboardingTitleView(
                title: LocalizedStringResource("\(PlatformDefinition.platformName) Model", bundle: .module),
                subtitle: LocalizedStringResource(
                    "Select the \(PlatformDefinition.platformName) model that you want to use.\nEnsure that your API key has proper access to the model.",
                    bundle: .module
                )
            )
        } content: {
            Picker(
                String(localized: "\(PlatformDefinition.platformName) Model", bundle: .module),
                selection: $selection
            ) {
                ForEach(models, id: \.self) { model in
                    Text(model.modelId)
                        .tag(model)
                }
            }
            #if !os(macOS)
            .pickerStyle(.wheel)
            #else
            .pickerStyle(PopUpButtonPickerStyle())
            #endif
            .accessibilityIdentifier("modelPicker")
        } footer: {
            OnboardingActionsView(title: { primaryActionTitle }) {
                action(selection)
            }
        }
    }
    
    /// - Parameters:
    ///   - primaryActionTitle: Localized text that should appear on the action button.
    ///   - models: The models that should be displayed in the picker user interface.
    ///   - initial: The initial model which should be selected.
    ///   - action: Action that should be performed after the OpenAI model selection has been done, selection is passed as closure argument.
    public init(
        _ primaryActionTitle: LocalizedStringResource? = nil,
        models: [PlatformDefinition.ModelType] = PlatformDefinition.ModelType.wellKnownModels,
        initial: PlatformDefinition.ModelType? = nil,
        action: @escaping @MainActor (PlatformDefinition.ModelType) -> Void
    ) {
        self.primaryActionTitle = primaryActionTitle.map(Text.init) ?? Text("Continue", bundle: .module)
        self.models = models
        self._selection = .init(initialValue: initial ?? .default)
        self.action = action
    }
    
    /// - Parameters:
    ///   - primaryActionTitle: Localized text that should appear on the action button.
    ///   - models: The models that should be displayed in the picker user interface.
    ///   - initial: The initial model which should be selected.
    ///   - action: Action that should be performed after the OpenAI model selection has been done, selection is passed as closure argument.
    @_disfavoredOverload
    public init(
        _ primaryActionTitle: some StringProtocol,
        models: [PlatformDefinition.ModelType] = PlatformDefinition.ModelType.wellKnownModels,
        initial: PlatformDefinition.ModelType? = nil,
        action: @escaping @MainActor (PlatformDefinition.ModelType) -> Void
    ) {
        self.primaryActionTitle = Text(primaryActionTitle)
        self.models = models
        self._selection = .init(initialValue: initial ?? .default)
        self.action = action
    }
}
