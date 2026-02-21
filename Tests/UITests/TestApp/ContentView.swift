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
            ForEach(Test.allCases) { test in
                NavigationLink(test.rawValue) {
                    test.view
                }
            }
        }
        .formStyle(.grouped)
    }
}


extension ContentView {
    enum Test: String, CaseIterable, Identifiable {
        case llmOpenAI = "LLMOpenAI"
        case llmLocal = "LLMLocal"
        case llmFog = "LLMFog"
        case llmOpenAIRealtime = "LLMOpenAIRealtime"
        case llmAnthropic = "LLMAnthropic"
        case llmGemini = "LLMGemini"
        
        var id: some Hashable {
            rawValue
        }
        
        @MainActor @ViewBuilder var view: some View {
            switch self {
            case .llmOpenAI:
                LLMOpenAILikeChatTestView<LLMOpenAIPlatformConfiguration>(model: .gpt4o)
            case .llmLocal:
                LLMLocalTestView()
            case .llmFog:
                LLMFogTestView()
            case .llmOpenAIRealtime:
                LLMOpenAIRealtimeTestView()
            case .llmAnthropic:
                LLMOpenAILikeChatTestView<LLMAnthropicPlatformConfiguration>(model: .opus4_6)
            case .llmGemini:
                LLMOpenAILikeChatTestView<LLMGeminiPlatformConfiguration>(model: .gemini2_5_pro)
            }
        }
    }
}
