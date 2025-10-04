//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


package protocol AudioCapableLLMSession: LLMSession {
    /// Returns a continuous stream of raw audio chunks (PCM16 format) produced by the underlying realtime LLM session.
    ///
    /// Each `Data` element in the stream represents a chunk of 16-bit PCM audio (mono, typically 24 kHz) that can be
    /// decoded or directly played by an audio engine. The stream will throw if a connection error occurs, and it automatically
    /// completes when the session ends or is cancelled.
    ///
    /// - Returns: An `AsyncThrowingStream` emitting `Data` objects containing PCM16 audio frames.
    /// - Throws: Errors surfaced by the underlying realtime connection.
    func listen() async -> AsyncThrowingStream<Data, any Error>
    
    /// Appends a chunk of audio (user input) to the session's input buffer.
    ///
    /// This method is used to stream audio samples from the microphone to the active realtime LLM session as the user speaks.
    ///
    /// - Important: No resampling or format conversion is performed by this method: audio should be provided in 16-bit PCM (little-endian), mono, 24 kHz.
    ///              Supplying a different format may result in degraded quality or server-side errors.
    /// - Parameter buffer: A block of raw PCM16 samples to send to the session's input audio buffer.
    /// - Throws: Any error encountered while sending the event over the realtime connection.
    /// - SeeAlso: ``endUserTurn()`` to commit the buffer and trigger a model response when not using VAD.
    ///
    /// Example
    /// ```swift
    /// while let pcmChunk = someRecorder.readPCM16Chunk() {
    ///     try await llmSession.appendUserAudio(pcmChunk)
    /// }
    /// ```
    func appendUserAudio(_ buffer: Data) async throws
    
    /// Commits the current input audio buffer and triggers a model response.
    ///
    /// This prompts the session to reply based on the audio previously appended via ``appendUserAudio(_:)``.
    ///
    /// This method is only required if turn detection is disabled (set to `nil`) in the session parameters.
    ///
    /// - Throws: Any error encountered while sending the commit or response request.
    /// - SeeAlso: ``appendUserAudio(_:)``
    func endUserTurn() async throws
    
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
    func events() async -> AsyncThrowingStream<LLMRealtimeAudioEvent, any Error>
}
