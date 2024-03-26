//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

#if os(iOS)
import SpeziAccount
#endif
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
    #if os(iOS)
    @State var presentingAccount = false
    #endif
    
    
    var body: some View {
        Group {
            if FeatureFlags.mockMode {
                LLMChatViewSchema(with: LLMMockSchema())
            } else {
                LLMChatViewSchema(with: Self.schema)
            }
        }
            .navigationTitle("LLM_FOG_CHAT_VIEW_TITLE")
            #if os(iOS)
            .sheet(isPresented: $presentingAccount) {
                AccountSheet()
            }
            .accountRequired {
                AccountSheet()
            }
            .verifyRequiredAccountDetails()
            #endif
            .accentColor(.orange)  // Fog Orange
    }
}
