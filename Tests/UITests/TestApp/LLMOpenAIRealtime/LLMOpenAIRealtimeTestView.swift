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

@Observable
@MainActor
final class AudioViewModel {
    private let replayUserAudio: Bool = true
    
    private let streamingService = AudioRecorder()
    // Used to play pcm from user's microphone (playback & debugging)
    private let pcmUserAudioPlayer = PCMPlayer()
    // Used to play pcm from OpenAI's result
    private let pcmOpenAiPlayer = PCMPlayer()

    // The microphone --> LLM task
    private var micTask: Task<Void, any Error>?
    // The LLM --> PCMPlayer (audio) task
    private var llmTask: Task<Void, any Error>?
    
    func setup(llm: LLMOpenAIRealtimeSession) {
        micTask = listenToMicrophone(with: llm)
        llmTask = playAssistantResponses(with: llm)
    }

    func listenToMicrophone(with llm: LLMOpenAIRealtimeSession) -> Task<Void, any Error> {
        Task { [weak self] in
            guard let audioBufferStream = self?.streamingService.audioBufferStream else {
                print("No audiobuffer stream..;")
                return
            }
            for try await pcm in audioBufferStream {
                do {
                    try await llm.appendUserAudio(pcm)
                } catch {
                    print("err", error)
                }

                if self?.replayUserAudio == true {
                    self?.pcmUserAudioPlayer.play(rawPCMData: pcm)
                }
            }
        }
    }
    
    func playAssistantResponses(with llm: LLMOpenAIRealtimeSession) -> Task<Void, any Error> {
        Task { [weak self] in
            let audioBufferStream = llm.listen()
            for try await pcm in audioBufferStream {
                self?.pcmOpenAiPlayer.play(rawPCMData: pcm)
            }
        }
    }

    func start() async {
        streamingService.start()
    }

    func stop() {
        streamingService.stop()
    }
    
    private func cancelTasks() {
        micTask?.cancel()
        micTask = nil
        llmTask?.cancel()
        llmTask = nil
    }
    
    deinit {
        print("Deinit of viewModel")
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                cancelTasks()
            }
        } else {
            assertionFailure("could not do cleanup, the action block is leaked")
        }
    }
}
