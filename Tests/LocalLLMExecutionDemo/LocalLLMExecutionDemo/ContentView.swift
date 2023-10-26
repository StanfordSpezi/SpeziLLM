//
// This source file is part of the SpeziML open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SwiftUI
import SpeziOnboarding


struct ContentView: View {
    @AppStorage(StorageKeys.onboardingFlowComplete) private var completedOnboardingFlow = false
    
    
    var body: some View {
        LocalLLMChatView()
            /// Presents an onboarding flow at startup, responsible for downloading the model
            .sheet(isPresented: !$completedOnboardingFlow) {
                OnboardingFlow()
            }
    }
}


#Preview {
    ContentView()
}
