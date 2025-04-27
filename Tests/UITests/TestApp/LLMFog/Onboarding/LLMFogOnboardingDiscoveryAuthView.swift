//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziLLMFog
import SpeziOnboarding
import SpeziViews
import SwiftUI


/// Onboarding view for authorizing local network access.
struct LLMFogOnboardingDiscoveryAuthView: View {
    @Environment(OnboardingNavigationPath.self) private var onboardingNavigationPath


    var body: some View {
        LLMFogDiscoveryAuthorizationView {
            onboardingNavigationPath.nextStep()
        }
    }
}


#if DEBUG
#Preview {
    OnboardingStack {
        LLMFogOnboardingDiscoveryAuthView()
    }
}
#endif
