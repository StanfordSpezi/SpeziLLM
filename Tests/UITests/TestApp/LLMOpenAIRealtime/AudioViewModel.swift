//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziLLMOpenAIRealtime
import SwiftUI

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
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                cancelTasks()
            }
        } else {
            assertionFailure("Could not do cleanup: is not running on MainThread...")
        }
    }
}
