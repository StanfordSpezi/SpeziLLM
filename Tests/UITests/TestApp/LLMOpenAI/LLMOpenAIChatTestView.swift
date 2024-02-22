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
    static let schema = LLMOpenAISchema(
        parameters: .init(
            modelType: .gpt4_turbo_preview,
            systemPrompt: "You're a helpful assistant that answers questions from users."
        )
    ) {
        LLMOpenAIFunctionWeather()
        LLMOpenAIFunctionHealthData()
        LLMOpenAIFunctionPerson()
    }
    
    @LLMSessionProvider(schema: Self.schema) var llm: LLMOpenAISession
    @State var showOnboarding = false
    @State var muted = true
    
    
    var body: some View {
        Group {
            if FeatureFlags.mockMode {
                LLMChatViewSchema(with: LLMMockSchema())
            } else {
                // Either use the convenience LLMChatViewSchema that only gets passed the schema. No access to underlying LLMSession
                // LLMChatViewSchema(with: Self.schema)
                
                // Otherwise use the LLMChatView and pass a LLMSession Binding in there. Use the @LLMSessionProvider wrapper to instantiate the LLMSession
                LLMChatView(session: $llm)
                    .speak(llm.context, muted: muted)
                    .speechToolbarButton(muted: $muted)
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
