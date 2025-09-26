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
    /// Returns a continuous stream of raw audio chunks (PCM16 format) produced by the Realtime API.
    ///
    /// Each `Data` element in the stream represents a chunk of 16-bit PCM audio at a sample rate of 24khz, that can be
    /// decoded or directly played by an audio engine. The stream will throw if a connection error occurs, and it automatically
    /// completes when the session ends or is cancelled.
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
    
    /// Appends a chunk of audio (user input) to the Realtime API's input buffer.
    ///
    /// This method is used to stream audio samples from the microphone to the OpenAI Realtime session as the user speaks.
    ///
    /// - Important: No resampling or format conversion is performed by this method: audio should be provided in 16-bit PCM (little-endian), mono, 24 kHz.
    ///              Supplying a different format may result in degraded quality or server-side errors.
    /// - Parameter buffer: A block of raw PCM16 samples to send to the Realtime API input audio buffer.
    /// - Throws: Any error encountered while sending the event over the realtime connection.
    /// - SeeAlso: ``endUserTurn()`` to commit the buffer and trigger a model response when not using VAD.
    ///
    /// Example
    /// ```swift
    /// while let pcmChunk = someRecorder.readPCM16Chunk() {
    ///     try await llmSession.appendUserAudio(pcmChunk)
    /// }
    /// ```
    public func appendUserAudio(_ buffer: Data) async throws {
        typealias InputAudioBufferAppend = Components.Schemas.RealtimeClientEventInputAudioBufferAppend

        try await apiConnection.sendMessage(
            InputAudioBufferAppend(
                _type: .input_audio_buffer_period_append,
                audio: buffer.base64EncodedString()
            )
        )
    }
    
    /// Commits the current input audio buffer and triggers a model response. 
    ///
    /// This prompts the Realtime API to reply based on the audio previously appended via ``appendUserAudio(_:)``.
    ///
    /// This method is only required if the ``LLMRealtimeTurnDetectionSettings`` have been set to nil in the ``LLMOpenAIRealtimeSchema`` parameters.
    ///
    /// - Throws: Any error encountered while sending the commit or response request.
    /// - SeeAlso: ``appendUserAudio(_:)``
    public func endUserTurn() async throws {
        typealias InputAudioBufferCommit = Components.Schemas.RealtimeClientEventInputAudioBufferCommit
        typealias RealtimeClientEventResponseCreate = Components.Schemas.RealtimeClientEventResponseCreate

        try await apiConnection.sendMessage(InputAudioBufferCommit(_type: .input_audio_buffer_period_commit))
        
        // Send a "response.create" event to reply something after the audio buffer has been commited
        try await apiConnection.sendMessage(RealtimeClientEventResponseCreate(_type: .response_period_create))
    }
    
    /// Returns a stream of Realtime events for advanced integrations.
    ///
    /// The returned stream yields `LLMRealtimeAudioEvent` values such as audio deltas, transcript
    /// updates, and lifecycle notifications. Use this if you need full control over rendering or state.
    /// For audio-only playback, prefer ``listen()`` which surfaces just the PCM16 audio chunks.
    ///
    /// The stream finishes when the session ends or the consuming task is cancelled. Errors from the
    /// underlying connection are surfaced via the stream.
    ///
    /// - Returns: An `AsyncThrowingStream` emitting `LLMRealtimeAudioEvent` values.
    ///
    /// Example
    /// ```swift
    /// for try await event in await session.events() {
    ///     switch event {
    ///     case .audioDelta(let pcm):
    ///         audioPlayer.enqueue(pcm)
    ///     case .assistantTranscriptDelta(let text):
    ///         ui.update(text)
    ///     default:
    ///         break
    ///     }
    /// }
    /// ```
    @_spi(Experimental)
    public func events() async -> AsyncThrowingStream<LLMRealtimeAudioEvent, any Error> {
        await apiConnection.events()
    }
    
    @MainActor
    func listenToLLMEvents() {
        // swiftlint:disable:next closure_body_length
        Task { [weak self] in
            guard let eventStream = await self?.apiConnection.events() else {
                Self.logger.error("SpeziLLMOpenAIRealtime: No self in listenToLLMEvents...")
                return
            }

            do {
                for try await event in eventStream {
                    switch event {
                    case .assistantTranscriptDelta(let content):
                        self?.context.append(assistantOutput: content)
                    case .assistantTranscriptDone:
                        self?.context.completeAssistantStreaming()
                    case .userTranscriptDelta(let content):
                        self?.handleTranscript(itemId: content.itemId, content: content.delta, isComplete: false)
                    case .userTranscriptDone(let content):
                        self?.handleTranscript(itemId: content.itemId, content: "", isComplete: true)
                    case .speechStopped(let content):
                        guard self?.schema.parameters.transcriptionSettings != nil else {
                            // No transcription is happening if no transcription settings are specified
                            break
                        }

                        // When speech stops, directly append an empty user message to ensure it
                        // appears before any assistant messages in the context. This message then 
                        // gets completed using the .userTranscriptDelta event
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
    
    /// Updates an existing context message by appending content, and optionally marking it as complete.
    ///
    /// If no message in the context has a UUID matching the deterministic UUID derived from `itemId`,
    /// this function does nothing and the content is ignored.
    @MainActor
    private func handleTranscript(itemId: String, content: String, isComplete: Bool) {
        let contentUUID = UUID.deterministic(from: itemId)
        let existingTranscriptIdx = self.context.firstIndex {
            $0.id == contentUUID
        }

        guard let existingTranscriptIdx = existingTranscriptIdx else {
            return
        }

        let existingMessage = self.context[existingTranscriptIdx]

        self.context[existingTranscriptIdx] = .init(
            role: .user,
            content: existingMessage.content + content,
            complete: isComplete,
            id: contentUUID,
            date: existingMessage.date
        )
    }
}
