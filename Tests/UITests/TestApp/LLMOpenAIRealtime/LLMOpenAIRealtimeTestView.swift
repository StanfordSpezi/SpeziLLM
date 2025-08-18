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

    @State var audio = AudioViewModel()
    
    var body: some View {
        VStack {
            Text("Hello, World!")
            Button {
                print("Start...")
                Task {
                    await audio.start(with: llm)
                }
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
        }.task {
            print("Init of LLM")
            let _ = try? await llm.generate()
        }
    }
}

@Observable
@MainActor
final class AudioViewModel {
    private let replayUserAudio: Bool = true
    
    private let streamingService = AudioRecorder()
    // Used to play pcm from user's microphone (playback & debugging)
    private let pcmUserAudioPlayer = PCMPlayer()
    // Used to play pcm from OpenAI's result
    private let pcmOpenAiPlayer = PCMPlayer()

    init() { }
    
    func start(with llm: LLMOpenAIRealtimeSession) async {
        streamingService.start()
        // TODO: Cancel this task correctly, otherwise llm doesn't get cancelled...
        Task {
            guard let audioBufferStream = streamingService.audioBufferStream else {
                print("No audiobuffer stream..;")
                return
            }
            for try await pcm in audioBufferStream {
                Task {
                    do {
                        try await llm.appendUserAudio(pcm)
                    } catch {
                        print("err", error)
                    }
                }
                if replayUserAudio {
                    pcmUserAudioPlayer.play(rawPCMData: pcm)
                }
            }
        }
    }

    func stop() {
        streamingService.stop()
    }
}
