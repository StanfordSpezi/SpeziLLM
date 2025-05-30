//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziOnboarding
import SwiftUI


/// Displays a multi-step onboarding flow for the Local LLM example application.
struct LLMLocalOnboardingFlow: View {
    @AppStorage(StorageKeys.localOnboardingFlowComplete) private var completedOnboardingFlow = false
    
    
    var body: some View {
        OnboardingStack(onboardingFlowComplete: $completedOnboardingFlow) {
            LLMLocalOnboardingWelcomeView()
            
            if !FeatureFlags.mockMode {
                LLMLocalOnboardingDownloadView()
            }
        }
        .interactiveDismissDisabled(!completedOnboardingFlow)
    }
}


#if DEBUG
#Preview {
    LLMLocalOnboardingFlow()
}
#endif
