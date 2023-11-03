//
// This source file is part of the SpeziML open-source project
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
struct LLMDownloadView: View {
    @EnvironmentObject private var onboardingNavigationPath: OnboardingNavigationPath
    
    
    var body: some View {
        LLMLocalDownloadView(
            llmDownloadUrl: LLMLocalDownloadManager.LLMUrlsDefaults.Llama2ChatModelUrl, /// By default, download the Llama2 model
            llmStorageUrl: .cachesDirectory.appending(path: "llm.gguf") /// Store the downloaded LLM in the caches directory
        ) {
            onboardingNavigationPath.nextStep()
        }
    }
}


#Preview {
    OnboardingStack {
        LLMDownloadView()
    }
}
