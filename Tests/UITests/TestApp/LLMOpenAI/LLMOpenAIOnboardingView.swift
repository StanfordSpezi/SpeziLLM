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
    var body: some View {
        OnboardingStack {
            LLMOpenAITokenOnboarding()
            LLMOpenAIModelOnboarding()
        }
    }
}
