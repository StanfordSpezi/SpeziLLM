//
// This source file is part of the Stanford Spezi Template Application open-source project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

#if os(iOS)
@_spi(TestingSupport) import SpeziAccount
import SpeziOnboarding
import SwiftUI


struct AccountOnboardingView: View {
    @Environment(OnboardingNavigationPath.self) private var onboardingNavigationPath


    var body: some View {
        AccountSetup { _ in
            Task {
                // Placing the nextStep() call inside this task will ensure that the sheet dismiss animation is
                // played till the end before we navigate to the next step.
                onboardingNavigationPath.nextStep()
            }
        } header: {
            AccountSetupHeader()
        } continue: {
            OnboardingActionsView(
                "Next",
                action: {
                    onboardingNavigationPath.nextStep()
                }
            )
        }
    }
}


#if DEBUG
#Preview("Account Onboarding SignIn") {
    OnboardingStack {
        AccountOnboardingView()
    }
        .previewWith {
            AccountConfiguration(service: InMemoryAccountService())
        }
}
#endif
#endif
