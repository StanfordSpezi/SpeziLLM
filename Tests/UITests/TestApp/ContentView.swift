//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Spezi
import SpeziLLMAnthropic
import SpeziLLMGemini
import SpeziLLMOpenAI
import SwiftUI


struct ContentView: View {
    var body: some View {
        Form {
            ForEach(Test.allCases, id: \.rawValue) { test in
                NavigationLink(test.rawValue) {
                    test.view
                }
            }
        }
        .formStyle(.grouped)
    }
}


extension ContentView {
    enum Test: String, CaseIterable {
        case llmOpenAI = "LLMOpenAI"
        case llmLocal = "LLMLocal"
        case llmFog = "LLMFog"
        case llmOpenAIRealtime = "LLMOpenAIRealtime"
        case llmAnthropic = "LLMAnthropic"
        case llmGemini = "LLMGemini"
        case mistral = "Mistral"
        case deepSeek = "DeepSeek"
        
        @MainActor @ViewBuilder var view: some View {
            switch self {
            case .llmOpenAI:
                LLMOpenAILikeChatTestView<OpenAIPlatformDefinition>(model: .gpt5_5_pro)
            case .llmLocal:
                LLMLocalTestView()
            case .llmFog:
                LLMFogTestView()
            case .llmOpenAIRealtime:
                LLMOpenAIRealtimeTestView()
            case .llmAnthropic:
                LLMOpenAILikeChatTestView<AnthropicPlatformDefinition>(model: .opus4_6)
            case .llmGemini:
                LLMOpenAILikeChatTestView<GeminiPlatformDefinition>(model: .gemini2_5_pro)
            case .deepSeek:
                LLMOpenAILikeChatTestView<DeepSeekPlatformDefinition>(model: .v4_flash)
            case .mistral:
                LLMOpenAILikeChatTestView<MistralPlatformDefinition>(model: .small_latest)
            }
        }
    }
}
