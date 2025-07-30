//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziLLM
import SpeziOnboarding
import SwiftUI


struct LLMFogTestView: View {
    @AppStorage(StorageKeys.fogOnboardingFlowComplete) private var completedOnboardingFlow = false


    var body: some View {
        LLMFogChatTestView()
            .sheet(isPresented: !$completedOnboardingFlow) {
                LLMFogOnboardingFlow()
                    #if os(macOS)
                    .frame(minWidth: 400, minHeight: 550)
                    #endif
            }
            .accentColor(.orange)  // Fog Orange
    }
}


#if DEBUG
#Preview {
    NavigationStack {
        LLMFogTestView()
    }
}
#endif
