//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziOnboarding
import SpeziViews
import SwiftUI


/// Onboarding Welcome view for the Local LLM example application.
struct LLMLocalOnboardingWelcomeView: View {
    @Environment(ManagedNavigationStack.Path.self) private var onboardingNavigationPath

    
    var body: some View {
        OnboardingView(
            title: "WELCOME_TITLE",
            subtitle: "WELCOME_SUBTITLE",
            areas: [
                OnboardingInformationView.Area(
                    icon: {
                        Image(systemName: "apps.iphone")
                            .accessibilityHidden(true)
                    },
                    title: "WELCOME_AREA1_TITLE",
                    description: "WELCOME_AREA1_DESCRIPTION"
                ),
                OnboardingInformationView.Area(
                    icon: {
                        Image(systemName: "shippingbox.fill")
                            .accessibilityHidden(true)
                    },
                    title: "WELCOME_AREA2_TITLE",
                    description: "WELCOME_AREA2_DESCRIPTION"
                ),
                OnboardingInformationView.Area(
                    icon: {
                        Image(systemName: "globe")
                            .accessibilityHidden(true)
                    },
                    title: "WELCOME_AREA3_TITLE",
                    description: "WELCOME_AREA3_DESCRIPTION"
                )
            ],
            actionText: "WELCOME_BUTTON",
            action: {
                onboardingNavigationPath.nextStep()
            }
        )
            .padding(.top, 24)
    }
}


#if DEBUG
#Preview {
    ManagedNavigationStack {
        LLMLocalOnboardingWelcomeView()
        LLMLocalOnboardingDownloadView()
    }
}
#endif
