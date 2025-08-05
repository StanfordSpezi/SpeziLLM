//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

#if os(iOS)
@_spi(TestingSupport) import SpeziAccount
#endif
import SpeziLLMFog
import SpeziViews
import SwiftUI


/// Displays a multi-step onboarding flow for the Fog LLM example application.
struct LLMFogOnboardingFlow: View {
    @AppStorage(StorageKeys.fogOnboardingFlowComplete) private var completedOnboardingFlow = false


    var body: some View {
        ManagedNavigationStack(didComplete: $completedOnboardingFlow) {
#if os(iOS)
            // Log into Firebase, required for fog node auth
            AccountOnboardingView()
#endif

            // Allow discovering and connecting to local network services
            LLMFogDiscoveryAuthOnboardingView()

            // Select available fog node within local network
            LLMFogDiscoverySelectionOnboardingView()

            // Potentially collect a static auth token for the fog node from user in onboarding
            // if auth token on `LLMFogPlatform` is specified as `RemoteLLMInferenceAuthToken/keychain(_:CredentialsTag)`.
            // LLMFogAuthTokenOnboardingView()
        }
            .interactiveDismissDisabled(!completedOnboardingFlow)
    }
}


#if DEBUG
#Preview {
    LLMFogOnboardingFlow()
#if os(iOS)
        .previewWith {
            AccountConfiguration(service: InMemoryAccountService())
        }
#endif
}
#endif
