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
            modelType: .init(value1: "gpt-4-turbo", value2: .gpt_hyphen_4_hyphen_turbo),
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
                    .speak(llm.context.chat, muted: muted)
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
                    #if os(macOS)
                    .frame(minWidth: 400, minHeight: 550)
                    #endif
            }
            .accentColor(Color(red: 0, green: 166 / 255, blue: 126 / 255))  // OpenAI Green
    }
}
