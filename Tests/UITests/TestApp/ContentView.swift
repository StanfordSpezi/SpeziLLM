//
// This source file is part of the SpeziML open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziOpenAI
import SwiftUI


struct ContentView: View {
    @State var chat: [Chat] = [
        Chat(role: .system, content: "System Message!"),
        Chat(role: .system, content: "System Message (hidden)!"),
        Chat(role: .function, content: "Function Message!"),
        Chat(role: .user, content: "User Message!"),
        Chat(role: .assistant, content: "Assistant Message!")
    ]
    @State var showOnboarding = false
    
    
    var body: some View {
        NavigationStack {
            ChatView($chat)
                .navigationTitle("Spezi ML")
                .toolbar {
                    ToolbarItem {
                        Button("Onboarding") {
                            showOnboarding.toggle()
                        }
                    }
                }
        }
            .sheet(isPresented: $showOnboarding) {
                OnboardingView()
            }
    }
}
