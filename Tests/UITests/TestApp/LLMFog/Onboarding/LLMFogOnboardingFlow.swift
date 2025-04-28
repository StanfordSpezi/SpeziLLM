//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziOnboarding
import SwiftUI


/// Displays a multi-step onboarding flow for the Fog LLM example application.
struct LLMFogOnboardingFlow: View {
    @AppStorage(StorageKeys.fogOnboardingFlowComplete) private var completedOnboardingFlow = false


    var body: some View {
        OnboardingStack(onboardingFlowComplete: $completedOnboardingFlow) {
#if os(iOS)
            // Log into Firebase, required for fog node auth
            AccountOnboardingView()
#endif

            // Allow discovering and connecting to local network services
            LLMFogOnboardingDiscoveryAuthView()
        }
            .interactiveDismissDisabled(!completedOnboardingFlow)
    }
}


#if DEBUG
#Preview {
    LLMFogOnboardingFlow()
}
#endif
