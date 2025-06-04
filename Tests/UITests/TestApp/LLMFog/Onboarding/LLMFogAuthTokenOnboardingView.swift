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


/// Onboarding view for getting a static auth token for the fog node.
///
/// - Important: Only use this view if the auth token on the `LLMFogPlatform` is set to `RemoteLLMInferenceAuthToken/keychain(_:CredentialsTag)`
struct LLMFogAuthTokenOnboardingView: View {
    @Environment(OnboardingNavigationPath.self) private var onboardingNavigationPath


    var body: some View {
        LLMFogAuthTokenOnboardingStep {
            onboardingNavigationPath.nextStep()
        }
    }
}


#if DEBUG
#Preview {
    OnboardingStack {
        LLMFogAuthTokenOnboardingView()
    }
        .previewWith {
            LLMFogPlatform(
                configuration: .init(
                    connectionType: .http,
                    authToken: .keychain(tag: .fogAuthToken, username: LLMFogConstants.credentialsUsername)
                )
            )
        }
}
#endif
