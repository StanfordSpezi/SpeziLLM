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

    /// The Spezi `LLM` that is configured and executed on the `LLMRunner`
    private var model: LLM = {
        if FeatureFlags.mockMode {
            LLMMock()
        } else {
            LLMOpenAI(
                parameters: .init(
                    modelType: .gpt4_1106_preview,
                    systemPrompt: "You're a helpful assistant that answers questions from users."
                ),
                functions: [
                    WeatherFunction(someArg: "")
                ]
            )
        }
    }()
    
    
    var body: some View {
        LLMChatView(
            model: model
        )
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
