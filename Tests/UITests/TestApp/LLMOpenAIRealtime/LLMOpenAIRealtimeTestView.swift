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
    static let schema = LLMOpenAIRealtimeSchema(parameters: .init(modelType: .gptRealtime)) {
        LLMOpenAIFunctionWeather()
    }

    @LLMSessionProvider(schema: Self.schema) var llm: LLMOpenAIRealtimeSession

    @State var audio = AudioViewModel()
    @State var showOnboarding = false


    var body: some View {
        LLMChatView(session: $llm)
        .toolbar {
            ToolbarItem {
                Button("LLM_OPENAI_CHAT_ONBOARDING_BUTTON") {
                    showOnboarding.toggle()
                }
            }
            ToolbarItemGroup(placement: .automatic) {
                Button {
                    toggleAudioRecording()
                } label: {
                    Text(audio.isRecording ? "Stop Recording" : "Start Recording")
                    Image(systemName: audio.isRecording ? "stop.circle.fill" : "record.circle")
                        .foregroundStyle(audio.isRecording ? .red : .accentColor)
                        .accessibilityHidden(true)
                }
            }
        }
        .sheet(isPresented: $showOnboarding) {
            LLMOpenAIRealtimeOnboardingView(session: $llm)
                #if os(macOS)
                .frame(minWidth: 400, minHeight: 550)
                #endif
        }
        .task {
            audio.setup(llm: llm)
        }
        .onChange(of: showOnboarding) { _, newValue in
            if !newValue {
                // When closing the onboarding sheet: Re-setup the realtime session
                llm.cancel()
                llm.state = .uninitialized
                audio.setup(llm: llm)
            }
        }
    }

    private func toggleAudioRecording() {
        if audio.isRecording {
            audio.stop()
        } else {
            Task { await audio.start() }
        }
    }
}
