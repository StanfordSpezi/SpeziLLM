//
//  LLMOPenAIRealtimeTestView.swift
//  SpeziLLM
//
//  Created by Sébastien Letzelter on 08.08.25.
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
    
    @State var audio = AudioVM()
    
    var body: some View {
        VStack {
            Text("Hello, World!")
            Button {
                print("Start...")
                Task {
                    await audio.start()
                }
//                llm.appendAu
//                Task {
//                    try await llm.appendUserAudio(Data())
//                }
            } label: {
                Text("Start")
            }
            Spacer().frame(height: 40)
            Button {
                print("Stop...")
                audio.stop()
//                llm.appendAu
//                Task {
//                    try await llm.appendUserAudio(Data())
//                }
            } label: {
                Text("Stop")
            }
        }
    }
}

@Observable
@MainActor
final class AudioVM {
    private let streamingService = AudioRecorder()
    private let pcmPlayer = PCMPlayer()

    func start() async {
        streamingService.start()
        
        Task {
            guard let audioBufferStream = streamingService.audioBufferStream else {
                print("No audiobuffer stream..;")
                return
            }
            for try await pcm in audioBufferStream {
                print("PCM: ", pcm.count, " bytes")
                pcmPlayer.play(rawPCMData: pcm)
            }
        }
    }

    func stop() {
        streamingService.stop()
    }
}
