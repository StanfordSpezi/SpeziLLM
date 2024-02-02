//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziChat
import SpeziLLM
import SpeziLLMOpenAI
import SwiftUI


struct LLMOpenAIChatTestView: View {
    @State var showOnboarding = false
    
    
    var body: some View {
        Group {
            if FeatureFlags.mockMode {
                LLMChatViewNew(
                    schema: LLMMockSchema()
                )
            } else {
                LLMChatViewNew(
                    schema: LLMOpenAISchema(
                        parameters: .init(
                            modelType: .gpt4_turbo_preview,
                            systemPrompt: "You're a helpful assistant that answers questions from users."
                        )
                    ) {
                        LLMOpenAIFunctionWeather()
                        LLMOpenAIFunctionHealthData()
                        LLMOpenAIFunctionPerson()
                    }
                )
            }
        }
            .navigationTitle("LLM_OPENAI_CHAT_VIEW_TITLE")
            .toolbar {
                ToolbarItem {
                    Button("LLM_OPENAI_CHAT_ONBOARDING_BUTTON") {
                        showOnboarding.toggle()
                    }
                }
            }
            .sheet(isPresented: $showOnboarding) {
                LLMOpenAIOnboardingView()
            }
            .accentColor(Color(red: 0, green: 166 / 255, blue: 126 / 255))  // OpenAI Green
    }
}
