//
// This source file is part of the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2022 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziOnboarding
import SwiftUI


/// Displays a multi-step onboarding flow for the Local LLM example application.
struct OnboardingFlow: View {
    @AppStorage(StorageKeys.onboardingFlowComplete) private var completedOnboardingFlow = false
    
    
    var body: some View {
        OnboardingStack(onboardingFlowComplete: $completedOnboardingFlow) {
            Welcome()
            LocalLLMDownloadView()
        }
        .interactiveDismissDisabled(!completedOnboardingFlow)
    }
}


#Preview {
    OnboardingFlow()
}
