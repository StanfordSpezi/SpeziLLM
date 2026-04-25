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


struct LLMOpenAILikeChatTestView<PlatformDefinition: LLMOpenAILikePlatformDefinition>: View {
    typealias Platform = LLMOpenAILikePlatform<PlatformDefinition>
    
    let schema: Platform.Schema
    @LLMSessionProvider<Platform.Schema> var llm: Platform.Session
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
//                    .speak(llm.context.chat, muted: muted)
//                    .speechToolbarButton(muted: $muted)
            }
        }
        .navigationTitle("LLM \(PlatformDefinition.platformName) Chat")
        .toolbar {
            ToolbarItem {
                Button("Onboarding") {
                    showOnboarding.toggle()
                }
            }
            ToolbarItem {
                Button("W") {
                    llm.context.append(userInput: "What's the weather in Munich, Berlin, and SF? (in Celsuis)")
                }
            }
        }
        .sheet(isPresented: $showOnboarding) {
            LLMOpenAILikeOnboardingView<PlatformDefinition>()
                #if os(macOS)
                .frame(minWidth: 400, minHeight: 550)
                #endif
        }
        .accentColor(Color(red: 0, green: 166 / 255, blue: 126 / 255))  // OpenAI Green
    }
    
    init(model: PlatformDefinition.ModelType) {
        schema = Platform.Schema(
            parameters: .init(
                modelType: model,
                systemPrompt: "You're a helpful assistant that answers questions from users.",
            )
        ) {
            LLMOpenAIFunctionWeather()
            LLMOpenAIFunctionHealthData()
            LLMOpenAIFunctionPerson()
            LLMOpenAIFunctionRecursive()
        }
        _llm = .init(schema: schema)
    }
}
