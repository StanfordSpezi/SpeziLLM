//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziLLM
import SpeziLLMOpenAI
import SpeziLLMOpenAIRealtime
import SwiftUI

struct LLMOpenAIRealtimeTestView: View {
    static let schema = LLMOpenAIRealtimeSchema {
        LLMOpenAIFunctionWeather()
        LLMOpenAIFunctionHealthData()
        LLMOpenAIFunctionPerson()
    }
    
    @LLMSessionProvider(schema: Self.schema) var llm: LLMOpenAIRealtimeSession

    @State var audio = AudioViewModel()
    
    var body: some View {
        VStack {
            LLMChatView(session: $llm)
            HStack {
                Button {
                    print("Start...")
                    Task {
                        await audio.start()
                    }
                } label: {
                    Text("Start")
                }
                Spacer().frame(width: 40)
                Button {
                    print("Stop...")
                    audio.stop()
                } label: {
                    Text("Stop")
                }
            }
        }.task {
            print("Init of LLM")
            _ = try? await llm.generate()
            audio.setup(llm: llm)
        }
    }
}
