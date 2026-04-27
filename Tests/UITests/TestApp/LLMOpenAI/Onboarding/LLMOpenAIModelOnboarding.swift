//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziLLMOpenAI
import SpeziViews
import SwiftUI


struct LLMOpenAILikeModelOnboarding<PlatformDefinition: LLMOpenAILikePlatformDefinition>: View {
    @Environment(ManagedNavigationStack.Path.self) private var path
    @State private var showingAlert = false
    @State private var modelSelection: PlatformDefinition.ModelType?
    
    var body: some View {
        Group {
            LLMOpenAILikeModelOnboardingStep<PlatformDefinition> { model in
                modelSelection = model
                showingAlert.toggle()
            }
        }
        .alert("LLM_OPENAI_MODEL_SELECTED", isPresented: $showingAlert) {
            Button("OK") {
                path.removeLast()
            }
        } message: {
            Text(modelSelection?.modelId ?? "No model selected")
        }
    }
}
