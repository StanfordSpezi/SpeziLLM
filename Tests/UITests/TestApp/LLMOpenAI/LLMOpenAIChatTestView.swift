//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziChat
import SwiftUI


struct LLMOpenAIChatTestView: View {
    @State var chat: Chat = [
        .init(role: .system, content: "System Message!"),
        .init(role: .system, content: "System Message (hidden)!"),
        .init(role: .function, content: "Function Message!"),
        .init(role: .user, content: "User Message!"),
        .init(role: .assistant, content: "Assistant Message!")
    ]
    @State var showOnboarding = false
    
    
    var body: some View {
        ChatView($chat)
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
            .accentColor(Color(red: 0, green: 166 / 255, blue: 126 / 255))  // OpenAI Green Color
    }
}
