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


/// Onboarding view for selecting a specific fog node to dispatch inference requests to
struct LLMFogDiscoverySelectionOnboardingView: View {
    @Environment(ManagedNavigationStack.Path.self) private var onboardingNavigationPath


    var body: some View {
        LLMFogDiscoverySelectionView { _ in
            onboardingNavigationPath.nextStep()
        }
    }
}


#if DEBUG
#Preview {
    ManagedNavigationStack {
        LLMFogDiscoverySelectionOnboardingView()
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
