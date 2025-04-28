//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziLLMOpenAI
import SpeziOnboarding
import SwiftUI


struct LLMOpenAITokenOnboarding: View {
    @Environment(OnboardingNavigationPath.self) private var path
    #if os(visionOS)
    @Environment(\.dismiss) private var dismiss
    #endif

    
    var body: some View {
        LLMOpenAIAPITokenOnboardingStep {
            path.nextStep()
        }
            #if os(visionOS)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .accessibilityLabel(Text("DISMISS_BUTTON_LABEL"))
                    }
                }
            }
            #endif
    }
}
