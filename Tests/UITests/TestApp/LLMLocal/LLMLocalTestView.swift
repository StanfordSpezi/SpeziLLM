//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziOnboarding
import SwiftUI


struct LLMLocalTestView: View {
    @AppStorage(StorageKeys.onboardingFlowComplete) private var completedOnboardingFlow = false
    
    
    var body: some View {
        LLMLocalChatTestView()
            .sheet(isPresented: !$completedOnboardingFlow) {
                LLMLocalOnboardingFlow()
            }
    }
}


#Preview {
    LLMLocalTestView()
}
