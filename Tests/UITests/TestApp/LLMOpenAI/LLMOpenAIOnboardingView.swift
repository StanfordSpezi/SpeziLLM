//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziOnboarding
import SwiftUI


struct LLMOpenAIOnboardingView: View {
    #if os(macOS)
    @Environment(\.dismiss) private var dismiss
    #endif
    
    
    var body: some View {
        OnboardingStack {
            LLMOpenAITokenOnboarding()
            LLMOpenAIModelOnboarding()
        }
            #if os(macOS)
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
