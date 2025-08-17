//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziLLMFog
import SpeziViews
import SwiftUI


/// Onboarding view for authorizing local network access.
struct LLMFogDiscoveryAuthOnboardingView: View {
    @Environment(ManagedNavigationStack.Path.self) private var onboardingNavigationPath


    var body: some View {
        LLMFogDiscoveryAuthorizationView {
            onboardingNavigationPath.nextStep()
        }
    }
}


#if DEBUG
#Preview {
    ManagedNavigationStack {
        LLMFogDiscoveryAuthOnboardingView()
    }
        .previewWith {
            LLMFogPlatform(
                configuration: .init(
                    connectionType: .http,
                    authToken: .keychain(
                        tag: .fogAuthToken,
                        username: LLMFogConstants.credentialsUsername
                    )
                )
            )
        }
}
#endif
