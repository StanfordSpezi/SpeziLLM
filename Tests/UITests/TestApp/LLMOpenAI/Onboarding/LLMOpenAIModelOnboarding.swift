//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziLLMOpenAI
import SpeziOnboarding
import SwiftUI


struct LLMOpenAIModelOnboarding: View {
    @Environment(OnboardingNavigationPath.self) private var path
    @State private var showingAlert = false
    @State private var modelSelection = ""
    
    var body: some View {
        Group {
            LLMOpenAIModelOnboardingStep { model in
                modelSelection = model
                self.showingAlert.toggle()
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("LLM_OPENAI_MODEL_SELECTED"),
                message: Text(modelSelection),
                dismissButton: .default(Text("OK"), action: {
                    path.removeLast()
                })
            )
        }
    }
}
