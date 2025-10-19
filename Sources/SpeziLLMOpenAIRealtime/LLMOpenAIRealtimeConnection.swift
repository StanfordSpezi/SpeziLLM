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
import SpeziLLM
import SpeziLLMOpenAI


actor LLMOpenAIRealtimeConnection {
    private typealias FunctionCallArgs = Components.Schemas.RealtimeServerEventResponseFunctionCallArgumentsDone
    private typealias RealtimeErrorEvent = Components.Schemas.RealtimeServerEventError

    enum RealtimeError: LLMError {
        case malformedUrlError
        case socketNotFoundError
        case openAIError(error: Components.Schemas.RealtimeServerEventError.errorPayload)
        case eventSessionUpdateSerialisationError
        case functionCallArgsNamelessError
    }
    
    private static let logger = Logger(subsystem: "edu.stanford.spezi", category: "SpeziLLMOpenAIRealtime")
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    private var eventLoopTask: Task<Void, any Error>?

    // Websocket Connection
    private var socket: URLSessionWebSocketTask?
    private lazy var urlSession = URLSession(configuration: .default)

    // The event stream which gets sent in session.events()
    private let eventStream = EventBroadcaster<LLMRealtimeAudioEvent>()

    // Handling of the setup: only finish whenever the connection to API has been successful
    private var readyContinuation: CheckedContinuation<Void, any Error>?

    func cancel() {
        eventLoopTask?.cancel()
        eventLoopTask = nil
        socket?.cancel()
        socket = nil
    }
    
    /// Returns a stream of Realtime events.
    ///
    /// The returned stream yields `LLMRealtimeAudioEvent` values such as audio deltas, transcript
    /// updates, function call requests, and lifecycle notifications.
    ///
    /// The stream obtained by calling this method finishes when the connection ends or the consuming task is cancelled.
    /// Errors are also emitted in this stream.
    ///
    /// - Returns: An `AsyncThrowingStream` emitting `LLMRealtimeAudioEvent` values.
    func events() async -> AsyncThrowingStream<LLMRealtimeAudioEvent, any Error> {
        // Creates an AsyncThrowingStream to listen to (so that there can be multiple listeners)
        await eventStream.observe()
    }
    
    func sendMessage(_ object: some Encodable) async throws {
        let objectJson = try Self.encoder.encode(object)
        try await socket?.send(.string(String(decoding: objectJson, as: UTF8.self)))
    }
    
    /// Opens socket connection to OpenAI's Realtime API and starts the event loop, which runs until calling `cancel()`
    /// Waits until the event loop has succesfully been initialized: only continues once session.created event is successfully received from socket
    func open(token: String, schema: LLMOpenAIRealtimeSchema) async throws {
        guard let realtimeApiUrl = URL(string: "wss://api.openai.com/v1/realtime?model=\(schema.parameters.modelType)") else {
            throw RealtimeError.malformedUrlError
        }
        
        var req = URLRequest(url: realtimeApiUrl)
        req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.addValue("realtime=v1", forHTTPHeaderField: "OpenAI-Beta")
        let webSocketTask = urlSession.webSocketTask(with: req)
        webSocketTask.resume()
        socket = webSocketTask
        
        try await startEventLoop(schema: schema)
    }
        
    /// Starts the event loop, which runs until calling `cancel()`
    /// Waits until the event loop has succesfully been initialized: only continues once session.created event is successfully received from socket
    private func startEventLoop(schema: LLMOpenAIRealtimeSchema) async throws {
        eventLoopTask = Task {
            do {
                try await self.eventLoop(schema: schema)
            } catch is CancellationError {
                readyContinuation?.resume(throwing: CancellationError())
                readyContinuation = nil
            } catch let error as NSError where
                        error.domain == NSPOSIXErrorDomain &&
                        error.code == Int(POSIXErrorCode.ENOTCONN.rawValue) &&
                        Task.isCancelled {
                // When Task got cancelled, resulting in Socket not connected error
                readyContinuation?.resume(throwing: CancellationError())
                readyContinuation = nil
            } catch {
                Self.logger.error("SpeziLLMOpenAiRealtime: LLMOpenAIRealtimeConnection eventLoop() failed with error: \(error)")
            }
        }
        // Await until we obtain session.created from OpenAI
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            readyContinuation = continuation
        }
    }
    
    // swiftlint:disable function_body_length cyclomatic_complexity closure_body_length
    /// Event loop function
    private func eventLoop(schema: LLMOpenAIRealtimeSchema) async throws {
        guard let socket = socket else {
            throw RealtimeError.socketNotFoundError
        }

        try await withTaskCancellationHandler {
            while true {
                let message = try await socket.receive()
                
                guard case let .string(text) = message else {
                    Self.logger.warning("RealtimeAPI Message is not of type .string")
                    continue
                }
                
                guard let messageJsonData = text.data(using: .utf8),
                          let messageDict = try? JSONSerialization.jsonObject(with: messageJsonData, options: [])  as? [String: Any]
                else {
                    Self.logger.warning("Invalid message format: \(text)")
                    continue
                }

                guard let type = messageDict["type"] as? String else {
                    Self.logger.warning("RealtimeAPI Message has no type")
                    continue
                }

                switch type {
                case "session.created":
                    try await sendSessionUpdate(schema: schema)
                case "session.updated":
                    readyContinuation?.resume()
                    readyContinuation = nil
                case "response.audio.delta":
                    guard let deltaBase64Str = messageDict["delta"] as? String,
                          let deltaPcmData = Data(base64Encoded: deltaBase64Str) else {
                        continue
                    }
                    let llmEvent = LLMRealtimeAudioEvent.audioDelta(deltaPcmData)
                    await eventStream.broadcast(llmEvent)
                case "response.audio.done":
                    guard let deltaBase64Str = messageDict["delta"] as? String,
                          let deltaPcmData = Data(base64Encoded: deltaBase64Str) else {
                        continue
                    }
                    let llmEvent = LLMRealtimeAudioEvent.audioDelta(deltaPcmData)
                    await eventStream.broadcast(llmEvent)
                case "response.audio_transcript.delta":
                    let transcript = messageDict["delta"] as? String ?? ""
                    await eventStream.broadcast(LLMRealtimeAudioEvent.assistantTranscriptDelta(transcript))
                case "response.audio_transcript.done":
                    let transcript = messageDict["transcript"] as? String ?? ""
                    await eventStream.broadcast(LLMRealtimeAudioEvent.assistantTranscriptDone(transcript))
                case "conversation.item.input_audio_transcription.delta":
                    let event = try Self.decoder.decode(LLMRealtimeAudioEvent.TranscriptDelta.self, from: messageJsonData)
                    await eventStream.broadcast(LLMRealtimeAudioEvent.userTranscriptDelta(event))
                case "conversation.item.input_audio_transcription.completed":
                    let event = try Self.decoder.decode(LLMRealtimeAudioEvent.TranscriptDone.self, from: messageJsonData)
                    await eventStream.broadcast(LLMRealtimeAudioEvent.userTranscriptDone(event))
                case "input_audio_buffer.speech_started":
                    let event = try Self.decoder.decode(LLMRealtimeAudioEvent.SpeechStarted.self, from: messageJsonData)
                    await eventStream.broadcast(LLMRealtimeAudioEvent.speechStarted(event))
                case "input_audio_buffer.speech_stopped":
                    let event = try Self.decoder.decode(LLMRealtimeAudioEvent.SpeechStopped.self, from: messageJsonData)
                    await eventStream.broadcast(LLMRealtimeAudioEvent.speechStopped(event))
                case "response.function_call_arguments.done":
                    let event = try Self.decoder.decode(FunctionCallArgs.self, from: messageJsonData)
                    await eventStream.broadcast(LLMRealtimeAudioEvent.functionCallRequested(
                        LLMOpenAIStreamResult.FunctionCall(
                            name: event.name,
                            id: event.call_id,
                            arguments: event.arguments
                        )
                    ))
                case "error":
                    let event = try Self.decoder.decode(RealtimeErrorEvent.self, from: messageJsonData)
                    let error = RealtimeError.openAIError(error: event.error)
                    readyContinuation?.resume(with: .failure(error))
                    readyContinuation = nil
                    await eventStream.finish(throwing: error)
                default:
                    break
                }
            }
        } onCancel: {
            Task {
                await eventStream.finish()
            }
        }
    }
    
    private func sendSessionUpdate(schema: LLMOpenAIRealtimeSchema) async throws {
        typealias ToolsPayload = Components.Schemas.RealtimeSessionCreateRequest.toolsPayloadPayload
        typealias TurnDetectionPayload = Components.Schemas.RealtimeSessionCreateRequest.turn_detectionPayload
        typealias RealtimeClientEventSessionUpdate = Components.Schemas.RealtimeClientEventSessionUpdate
        typealias RealtimeSessionCreateRequest = Components.Schemas.RealtimeSessionCreateRequest

        let tools: [ToolsPayload] = try schema.functions.values.compactMap { function in
            let functionType = Swift.type(of: function)
            let encodedSchema = try Self.encoder.encode(try function.schema)
            let jsonObject = try JSONSerialization.jsonObject(with: encodedSchema) as? [String: any Sendable] ?? [:]

            return ToolsPayload(
                _type: .function,
                name: functionType.name,
                description: functionType.description,
                parameters: try .init(unvalidatedValue: jsonObject)
            )
        }
        
        let transcriptionSettings = schema.parameters.transcriptionSettings
        
        let eventSessionUpdate = RealtimeClientEventSessionUpdate(
            _type: .session_period_update,
            session: .init(
                instructions: schema.parameters.systemPrompt,
                voice: schema.parameters.voice
                    .flatMap { val in .init(rawValue: val.rawValue) },
                input_audio_transcription: transcriptionSettings == nil ? nil : RealtimeSessionCreateRequest
                    .input_audio_transcriptionPayload(
                        model: transcriptionSettings?.model.rawValue,
                        language: transcriptionSettings?.language?.identifier,
                        prompt: transcriptionSettings?.prompt,
                    ),
                tools: tools,
            )
        )
        
        let eventSessionUpdateData = try Self.encoder.encode(eventSessionUpdate)
        guard var eventSessionUpdateJson = try JSONSerialization.jsonObject(with: eventSessionUpdateData) as? [String: Any],
              var session = eventSessionUpdateJson["session"] as? [String: Any] else {
            throw RealtimeError.eventSessionUpdateSerialisationError
        }

        // Handle turn_detection directly on the JSON object, as the GeneratedOpenAIClient isn't up-to-date
        // and JSONEncoder() is ommiting `nil` values instead of returning as "null"
        if let turnDetectionSettings = schema.parameters.turnDetectionSettings {
            let turnDetectionData = try Self.encoder.encode(turnDetectionSettings)
            let turnDetectionObj = try JSONSerialization.jsonObject(with: turnDetectionData, options: [])
            session["turn_detection"] = turnDetectionObj
            eventSessionUpdateJson["session"] = session
        } else {
            // turnDetectionSettings set to nil: Explicitely set turn_detection to "null" to disable turn detection entirely
            session["turn_detection"] = NSNull()
            eventSessionUpdateJson["session"] = session
        }

        let finalData = try JSONSerialization.data(withJSONObject: eventSessionUpdateJson)


        try await socket?.send(.string(String(decoding: finalData, as: UTF8.self)))
        Self.logger.debug("Sent session update:\n\(String(decoding: finalData, as: UTF8.self))")
    }
}
