//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziLLMLocalDownload
import SpeziOnboarding
import SpeziViews
import SwiftUI


/// Onboarding LLM Download view for the Local LLM example application.
struct LLMLocalOnboardingDownloadView: View {
    @Environment(OnboardingNavigationPath.self) private var onboardingNavigationPath
    
    
    var body: some View {
        LLMLocalDownloadView(
            model: .phi3_4bit,
            downloadDescription: "LLM_DOWNLOAD_DESCRIPTION",
            action: onboardingNavigationPath.nextStep
        )
    }
}


#if DEBUG
#Preview {
    OnboardingStack {
        LLMLocalOnboardingDownloadView()
    }
}
#endif
