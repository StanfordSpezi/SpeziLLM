//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable file_types_order

import Spezi
import SpeziOnboarding
import SwiftUI


/// View to display an onboarding step for the user to enter change the OpenAI model.
public typealias LLMOpenAIModelOnboardingStep = LLMOpenAILikeModelOnboardingStep<LLMOpenAIPlatformConfiguration>


/// View to display an onboarding step for the user to select an OpenAI-like model.
public struct LLMOpenAILikeModelOnboardingStep<PlatformConfig: LLMOpenAILikePlatformConfiguration>: View {
    @Environment(\.colorScheme) private var colorScheme
    
    private let continueTitle: LocalizedStringResource
    private let models: [PlatformConfig.ModelType]
    // why is this a closure instead of passing in a binding?
    private let action: @MainActor (PlatformConfig.ModelType) -> Void
    
    @State private var selection: PlatformConfig.ModelType
    
    public var body: some View {
        OnboardingView {
            OnboardingTitleView(
                title: LocalizedStringResource("\(PlatformConfig.platformName) Model", bundle: .module),
                subtitle: LocalizedStringResource(
                    "Select the \(PlatformConfig.platformName) model that you want to use.\nEnsure that your API key has proper access to the model.",
                    bundle: .module
                )
            )
        } content: {
            Picker(
                String(localized: "\(PlatformConfig.platformName) Model", bundle: .module),
                selection: $selection
            ) {
                ForEach(models) { model in
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
        } footer: {
            OnboardingActionsView(continueTitle) {
                action(selection)
            }
        }
    }
    
    /// - Parameters:
    ///   - actionText: Localized text that should appear on the action button.
    ///   - models: The models that should be displayed in the picker user interface.
    ///   - initial: The initial model which should be selected.
    ///   - action: Action that should be performed after the OpenAI model selection has been done, selection is passed as closure argument.
    public init(
        continueTitle: LocalizedStringResource? = nil,
        models: [PlatformConfig.ModelType] = PlatformConfig.ModelType.wellKnownModels,
        initial: PlatformConfig.ModelType? = nil,
        action: @escaping @MainActor (PlatformConfig.ModelType) -> Void
    ) {
        self.continueTitle = continueTitle ?? LocalizedStringResource("Continue", bundle: .module)
        self.models = models
        self._selection = .init(initialValue: initial ?? .default)
        self.action = action
    }
}
