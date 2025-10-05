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
}
