//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import GeneratedOpenAIClient

extension LLMOpenAIRealtimeSession: AudioCapableLLMSession {
    /// Returns a continuous stream of raw audio chunks (PCM16 format) produced by the OpenAI Realtime API.
    ///
    /// Each `Data` element in the stream represents a chunk of 16-bit PCM audio that can be
    /// decoded or directly played by an audio engine. The stream will throw if a connection
    /// error occurs, and it automatically completes when the session ends or is cancelled.
    ///
    /// - Returns: An `AsyncThrowingStream` emitting `Data` objects containing PCM16 audio frames.
    /// - Throws: Errors related to the underlying Realtime API connection.
    public func listen() -> AsyncThrowingStream<Data, any Error> {
        // Filters the events from `apiConnection.events()` to only keep the `RealtimeLLMEvent.audioDelta(delta)` ones.
        // Then emits the `delta: Data` value onto the stream.
        AsyncThrowingStream { [apiConnection] continuation in
            let task = Task {
                do {
                    for try await event in await apiConnection.events() {
                        if case .audioDelta(let delta) = event {
                            continuation.yield(delta) // emit pcm16 chunk
                        }
                    }
                    continuation.finish() // upstream ended normally
                } catch {
                    continuation.finish(throwing: error) // propagate upstream error
                }
            }
            
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
    
    /// Used to append audio from the user's mic, directly sends it to OpenAI
    public func appendUserAudio(_ buffer: Data) async throws {
        let eventData = Components.Schemas.RealtimeClientEventInputAudioBufferAppend(
            _type: .input_audio_buffer_period_append,
            audio: buffer.base64EncodedString()
        )
        
        let encoder = JSONEncoder()
        let eventDataJson = try encoder.encode(eventData)
        try await apiConnection.socket?.send(.string(String(decoding: eventDataJson, as: UTF8.self)))
    }
    
    /// Only used when having manual VAD: asks OpenAI to generate response event to obtain audio / transcripts
    public func endUserTurn() async throws {
        // TODO: Handle manual mode
    }
    
    /// For very custom UIs: you can use `events()` which returns a stream with the actual OpenAI Realtime events
    public func events() async -> AsyncThrowingStream<RealtimeLLMEvent, any Error> {
        await apiConnection.events()
    }
    
    @MainActor
    internal func listenToLLMEvents() {
        Task { [weak self] in
            guard let eventStream = await self?.apiConnection.events() else {
                Self.logger.error("SpeziLLMOpenAIRealtime: No self in listenToLLMEvents...")
                return
            }

            do {
                for try await event in eventStream {
                    switch event {
                        // TODO: Fix order of context appends (user & assistant)
                    case .assistantTranscriptDelta(let content):
                        await MainActor.run { self?.context.append(assistantOutput: content) }
                    case .assistantTranscriptDone:
                        await MainActor.run { self?.context.completeAssistantStreaming() }
                    case .userTranscriptDone(let content):
                        await MainActor.run { self?.context.append(userInput: content) }
                    default:
                        break
                    }
                }
            } catch {
                Self.logger.error("SpeziLLMOpenAIRealtime: Listening to LLM Event threw error: \(error)")
            }
        }
    }
}
