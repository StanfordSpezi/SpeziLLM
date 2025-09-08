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
    static let schema = LLMOpenAIRealtimeSchema(parameters: .init(modelType: .gpt4o_realtime)) {
        LLMOpenAIFunctionWeather()
    }
    
    @LLMSessionProvider(schema: Self.schema) var llm: LLMOpenAIRealtimeSession

    @State var audio = AudioViewModel()
    
    var body: some View {
        VStack {
            LLMChatView(session: $llm)

            HStack {
                Button {
                    Task {
                        if audio.isRecording {
                            audio.stop()
                        } else {
                            await audio.start()
                        }
                    }
                } label: {
                    Text(audio.isRecording ? "Stop Recording" : "Start Recording")
                }.buttonStyle(.bordered)
            }
        }.onAppear {
            audio.setup(llm: llm)
        }
    }
}
