//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziChat
import SpeziLLM
import SpeziLLMFog
import SwiftUI


struct LLMFogChatTestView: View {
    static let schema = LLMFogSchema(
        parameters: .init(
            modelType: .llama7B,
            systemPrompt: "You're a helpful assistant that answers questions from users."
        )
    )
    
    @State var showOnboarding = false
    @State var presentingAccount = false
    
    
    var body: some View {
        Group {
            if FeatureFlags.mockMode {
                LLMChatViewSchema(with: LLMMockSchema())
            } else {
                LLMChatViewSchema(with: Self.schema)
            }
        }
            .navigationTitle("LLM_FOG_CHAT_VIEW_TITLE")
            .sheet(isPresented: $presentingAccount) {
                AccountSheet()
            }
            .accountRequired {
                AccountSheet()
            }
            .verifyRequiredAccountDetails()
        /*
            .toolbar {
                ToolbarItem {
                    Button("LLM_OPENAI_CHAT_ONBOARDING_BUTTON") {
                        showOnboarding.toggle()
                    }
                }
            }
         
            .sheet(isPresented: $showOnboarding) {
                LLMOpenAIOnboardingView()
                    #if os(macOS)
                    .frame(minWidth: 400, minHeight: 550)
                    #endif
            }
         */
            .accentColor(.orange)  // Fog Orange
    }
}
