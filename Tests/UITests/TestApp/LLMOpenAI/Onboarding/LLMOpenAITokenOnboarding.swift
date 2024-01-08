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

    
    var body: some View {
        LLMOpenAIAPITokenOnboardingStep {
            path.nextStep()
        }
    }
}
