//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Foundation
import GeneratedOpenAIClient
import os

actor LLMOpenAIRealtimeConnection {
    typealias RealtimeClientEventSessionUpdate = Components.Schemas.RealtimeClientEventSessionUpdate

    enum RealtimeError: Error {
        case malformedUrlError
        case socketNotFoundError
        case openAIError
    }

    static let logger = Logger(subsystem: "edu.stanford.spezi", category: "SpeziLLMOpenAIRealtime")

    private var eventLoopTask: Task<Void, any Error>?

    // Websocket Connection
    internal var socket: URLSessionWebSocketTask?
    private lazy var urlSession = URLSession(configuration: .default)

    // The event stream which gets sent in session.events()
    private let eventStream = EventBroadcaster<RealtimeLLMEvent>()

    // Handling of the setup: only finish whenever the connection to API has been succesful
    private var readyContinuation: CheckedContinuation<Void, any Error>?

    func cancel() {
        eventLoopTask?.cancel()
        eventLoopTask = nil
        socket?.cancel()
        socket = nil
    }
    
    func events() async -> AsyncThrowingStream<RealtimeLLMEvent, any Error> {
        // Creates an AsyncThrowingStream to listen to (so that there can be multiple listeners)
        await eventStream.stream()
    }
    
    /// Opens socket connection to OpenAI's Realtime API
    func open(token: String, model: String) async throws {
        guard let realtimeApiUrl = URL(string: "wss://api.openai.com/v1/realtime?model=\(model)") else {
            throw RealtimeError.malformedUrlError
        }
        
        var req = URLRequest(url: realtimeApiUrl)
        req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.addValue("realtime=v1", forHTTPHeaderField: "OpenAI-Beta")
        let webSocketTask = urlSession.webSocketTask(with: req)
        webSocketTask.resume()
        socket = webSocketTask
    }
    
    /// Starts the event loop, which runs until calling `cancel()`
    /// Waits until the event loop has succesfully been initialized: only continues once session.created event is successfully received from socket
    func startEventLoop() async throws {
        eventLoopTask = Task {
            do {
                try await self.eventLoop()
            } catch is CancellationError {
            } catch let error as NSError where
                        error.domain == NSPOSIXErrorDomain &&
                        error.code == Int(POSIXErrorCode.ENOTCONN.rawValue) &&
                        Task.isCancelled {
                // When Task got cancelled & Socket is not connected error: ignore
            } catch {
                Self.logger.error("SpeziLLMOpenAiRealtime: LLMOpenAIRealtimeConnection eventLoop() failed with error: \(error.localizedDescription)")
            }
        }
        // Await until we obtain session.created from OpenAI
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            readyContinuation = continuation
        }
    }
    
    // swiftlint:disable function_body_length cyclomatic_complexity closure_body_length
    /// Event loop function
    private func eventLoop() async throws {
        guard let socket = socket else {
            throw RealtimeError.socketNotFoundError
        }

        try await withTaskCancellationHandler {
            while true {
                let message = try await socket.receive()
                
                if case let .string(text) = message {
                    guard let messageJsonData = text.data(using: .utf8),
                          let messageDict = try? JSONSerialization.jsonObject(with: messageJsonData, options: [])  as? [String: Any]
                    else {
                        Self.logger.warning("Invalid message format: \(text)")
                        continue
                    }
                    
                    if let type = messageDict["type"] as? String {
                        switch type {
                        case "session.created":
                            print("Session created!")
                            Task {
                                try await sendSessionUpdate()
                                readyContinuation?.resume()
                                readyContinuation = nil
                            }
                        case "response.audio.delta":
                            guard let deltaPcmData = Data(base64Encoded: messageDict["delta"] as? String ?? "") else {
                                continue
                            }
                            let llmEvent = RealtimeLLMEvent.audioDelta(deltaPcmData)
                            await eventStream.yield(llmEvent)
                        case "response.audio.done":
                            guard let deltaPcmData = Data(base64Encoded: messageDict["delta"] as? String ?? "") else {
                                continue
                            }
                            let llmEvent = RealtimeLLMEvent.audioDelta(deltaPcmData)
                            await eventStream.yield(llmEvent)
                        case "response.audio_transcript.delta":
                            let transcript = messageDict["delta"] as? String ?? ""
                            let llmEvent = RealtimeLLMEvent.assistantTranscriptDelta(transcript)
                            await eventStream.yield(llmEvent)
                        case "response.audio_transcript.done":
                            let transcript = messageDict["transcript"] as? String ?? ""
                            let llmEvent = RealtimeLLMEvent.assistantTranscriptDone(transcript)
                            await eventStream.yield(llmEvent)
                        case "conversation.item.input_audio_transcription.delta":
                            let event = try JSONDecoder().decode(TranscriptDeltaEvent.self, from: messageJsonData)
                            let llmEvent = RealtimeLLMEvent.userTranscriptDelta(event)
                            await eventStream.yield(llmEvent)
                        case "conversation.item.input_audio_transcription.completed":
                            let event = try JSONDecoder().decode(TranscriptDoneEvent.self, from: messageJsonData)
                            let llmEvent = RealtimeLLMEvent.userTranscriptDone(event)
                            await eventStream.yield(llmEvent)
                        case "input_audio_buffer.speech_started":
                            let event = try JSONDecoder().decode(SpeechStartedEvent.self, from: messageJsonData)
                            let llmEvent = RealtimeLLMEvent.speechStarted(event)
                            await eventStream.yield(llmEvent)
                        case "input_audio_buffer.speech_stopped":
                            await eventStream.yield(RealtimeLLMEvent.speechStopped)
                        case "error":
                            readyContinuation?.resume(with: .failure(RealtimeError.openAIError))
                            readyContinuation = nil
                            await eventStream.finish(throwing: RealtimeError.openAIError)
                        default:
                            break
                        }
                    }
                }
            }
        } onCancel: {
            Task {
                await eventStream.finish()
            }
        }
    }

    func sendSessionUpdate() async throws {
        // TODO: Add tools and turn detection settings!
        let eventSessionUpdate = RealtimeClientEventSessionUpdate(
            _type: .session_period_update,
            session: .init(
//                turn_detection: turnDetection,
//                tools: tools
                input_audio_transcription: Components.Schemas.RealtimeSessionCreateRequest
                    .input_audio_transcriptionPayload(model: "gpt-4o-mini-transcribe")
            )
        )

        
        let eventSessionUpdateJson = try JSONEncoder().encode(eventSessionUpdate)
        try await socket?.send(.string(String(decoding: eventSessionUpdateJson, as: UTF8.self)))
        Self.logger.debug("Sent session update:\n\(String(decoding: eventSessionUpdateJson, as: UTF8.self))")
    }
}
