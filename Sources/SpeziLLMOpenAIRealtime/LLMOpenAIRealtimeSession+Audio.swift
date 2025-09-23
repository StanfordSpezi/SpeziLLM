//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import GeneratedOpenAIClient
import SpeziLLM


extension LLMOpenAIRealtimeSession: AudioCapableLLMSession {
    /// Returns a continuous stream of raw audio chunks (PCM16 format) produced by the OpenAI Realtime API.
    ///
    /// Each `Data` element in the stream represents a chunk of 16-bit PCM audio that can be
    /// decoded or directly played by an audio engine. The stream will throw if a connection
    /// error occurs, and it automatically completes when the session ends or is cancelled.
    ///
    /// - Returns: An `AsyncThrowingStream` emitting `Data` objects containing PCM16 audio frames.
    /// - Throws: Errors related to the underlying Realtime API connection.
    public func listen() async -> AsyncThrowingStream<Data, any Error> {
        guard let wasSetupSuccessful = try? await ensureSetup(), wasSetupSuccessful else {
            return AsyncThrowingStream { continuation in
                continuation.finish()
            }
        }

        // Filters the events from `apiConnection.events()` to only keep the `LLMRealtimeAudioEvent.audioDelta(delta)` ones.
        // Then emits the `delta: Data` value onto the stream.
        return AsyncThrowingStream { [apiConnection] continuation in
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
        typealias InputAudioBufferAppend = Components.Schemas.RealtimeClientEventInputAudioBufferAppend

        try await apiConnection.sendMessage(
            InputAudioBufferAppend(
                _type: .input_audio_buffer_period_append,
                audio: buffer.base64EncodedString()
            )
        )
    }
    
    /// Only used when having no VAD: ask OpenAI to generate response event to obtain audio / transcripts
    public func endUserTurn() async throws {
        typealias InputAudioBufferCommit = Components.Schemas.RealtimeClientEventInputAudioBufferCommit
        typealias RealtimeClientEventResponseCreate = Components.Schemas.RealtimeClientEventResponseCreate

        try await apiConnection.sendMessage(InputAudioBufferCommit(_type: .input_audio_buffer_period_commit))
        
        // Send a "response.create" event to reply something after the audio buffer has been commited
        try await apiConnection.sendMessage(RealtimeClientEventResponseCreate(_type: .response_period_create))
    }
    
    /// For very custom UIs: you can use `events()` which returns a stream with the actual OpenAI Realtime events
    public func events() async -> AsyncThrowingStream<LLMRealtimeAudioEvent, any Error> {
        await apiConnection.events()
    }
    
    // swiftlint:disable closure_body_length cyclomatic_complexity function_body_length
    @MainActor
    func listenToLLMEvents() {
        Task { [weak self] in
            guard let eventStream = await self?.apiConnection.events() else {
                Self.logger.error("SpeziLLMOpenAIRealtime: No self in listenToLLMEvents...")
                return
            }

            do {
                for try await event in eventStream {
                    switch event {
                    case .assistantTranscriptDelta(let content):
                        await MainActor.run { self?.context.append(assistantOutput: content) }
                    case .assistantTranscriptDone:
                        await MainActor.run { self?.context.completeAssistantStreaming() }
                    case .userTranscriptDelta(let content):
                        await MainActor.run {
                            let contentUUID = UUID.deterministic(from: content.itemId)
                            let existingTranscriptIdx = self?.context
                                .firstIndex { $0.id == contentUUID }
                            if let existingTranscriptIdx = existingTranscriptIdx,
                                let existingMessage = self?.context[existingTranscriptIdx] {
                                self?.context[existingTranscriptIdx] = .init(
                                    role: .user,
                                    content: existingMessage.content + content.delta,
                                    complete: false,
                                    id: contentUUID,
                                    date: existingMessage.date
                                )
                            }
                        }
                    case .userTranscriptDone(let content):
                        await MainActor.run {
                            let contentUUID = UUID.deterministic(from: content.itemId)
                            let existingTranscriptIdx = self?.context
                                .firstIndex { $0.id == contentUUID }
                            if let existingTranscriptIdx = existingTranscriptIdx,
                                let existingMessage = self?.context[existingTranscriptIdx] {
                                self?.context[existingTranscriptIdx] = .init(
                                    role: .user,
                                    content: existingMessage.content,
                                    complete: true,
                                    id: contentUUID,
                                    date: existingMessage.date
                                )
                            }
                        }

                    case .speechStarted(let content):
                        guard self?.schema.parameters.transcriptionSettings != nil else {
                            // No transcription is happening if no transcription settings are specified
                            break
                        }

                        // When speech starts, add a context message at the correct spot (to retain order)
                        // This message then gets completed using the .userTranscriptDelta event
                        let contentUUID = UUID.deterministic(from: content.itemId)
                        self?.context
                            .append(
                                .init(
                                    role: .user,
                                    content: "",
                                    complete: false,
                                    id: contentUUID,
                                    date: Date.now
                                )
                            )
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
