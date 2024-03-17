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


struct LLMLocalTestView: View {
    @AppStorage(StorageKeys.onboardingFlowComplete) private var completedOnboardingFlow = false
    let mockMode: Bool
    
    
    var body: some View {
        LLMLocalChatTestView(mockMode: mockMode)
            .sheet(isPresented: !$completedOnboardingFlow) {
                LLMLocalOnboardingFlow()
                    #if os(macOS)
                    .frame(minWidth: 400, minHeight: 550)
                    #endif
            }
    }
    
    
    init(mockMode: Bool = false) {
        self.mockMode = mockMode
    }
}


#if DEBUG
#Preview {
    NavigationStack {
        LLMLocalTestView(mockMode: true)
    }
        .previewWith {
            LLMRunner {
                LLMMockPlatform()
            }
        }
}
#endif
