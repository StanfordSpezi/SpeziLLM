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
    package enum RealtimeError: Error {
        case malformedUrlError
        case socketNotFoundError
        case openAIError(error: [String: any Sendable])
        case eventSessionUpdateSerialisationError
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
    func startEventLoop(platform: LLMOpenAIRealtimePlatform, schema: LLMOpenAIRealtimeSchema) async throws {
        eventLoopTask = Task {
            do {
                try await self.eventLoop(platform: platform, schema: schema)
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
    private func eventLoop(platform: LLMOpenAIRealtimePlatform, schema: LLMOpenAIRealtimeSchema) async throws {
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
                            Task {
                                try await sendSessionUpdate(platform: platform, schema: schema)
                            }
                        case "session.updated":
                            readyContinuation?.resume()
                            readyContinuation = nil
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
                            let event = try JSONDecoder().decode(RealtimeLLMEvent.TranscriptDelta.self, from: messageJsonData)
                            let llmEvent = RealtimeLLMEvent.userTranscriptDelta(event)
                            await eventStream.yield(llmEvent)
                        case "conversation.item.input_audio_transcription.completed":
                            let event = try JSONDecoder().decode(RealtimeLLMEvent.TranscriptDone.self, from: messageJsonData)
                            let llmEvent = RealtimeLLMEvent.userTranscriptDone(event)
                            await eventStream.yield(llmEvent)
                        case "input_audio_buffer.speech_started":
                            let event = try JSONDecoder().decode(RealtimeLLMEvent.SpeechStarted.self, from: messageJsonData)
                            let llmEvent = RealtimeLLMEvent.speechStarted(event)
                            await eventStream.yield(llmEvent)
                        case "input_audio_buffer.speech_stopped":
                            await eventStream.yield(RealtimeLLMEvent.speechStopped)
                        case "response.function_call_arguments.done":
                            let event = try JSONDecoder().decode(RealtimeLLMEvent.FunctionCall.self, from: messageJsonData)
                            Task {
                                do {
                                    try await handleFunctionCall(schema: schema, event: event)
                                } catch {
                                    Self.logger.error("SpeziLLMOpenAIRealtime: Function call handler failed: \(error)")
                                }
                            }
                        case "error":
                            let error = RealtimeError.openAIError(error: messageDict["error"] as? [String: any Sendable] ?? [:])
                            readyContinuation?.resume(with: .failure(error))
                            readyContinuation = nil
                            await eventStream.finish(throwing: error)
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
    
    private func handleFunctionCall(schema: LLMOpenAIRealtimeSchema, event: RealtimeLLMEvent.FunctionCall) async throws {
        typealias ConversationItemCreateEvent = Components.Schemas.RealtimeClientEventConversationItemCreate
        typealias RealtimeClientEventResponseCreate = Components.Schemas.RealtimeClientEventResponseCreate

        let argumentData = event.arguments.data(using: .utf8) ?? Data()

        try schema.functions[event.name]?.injectParameters(from: argumentData)
        let output = try await schema.functions[event.name]?.execute()

        let conversationItem = ConversationItemCreateEvent(
            _type: .conversation_period_item_period_create,
            item: .init(
                _type: .function_call_output,
                call_id: event.callId,
                output: output
            )
        )
        
        let conversationItemJson = try JSONEncoder().encode(conversationItem)
        try await socket?.send(.string(String(decoding: conversationItemJson, as: UTF8.self)))
        
        // Send a "response.create" event to reply something after the function call
        let responseData = RealtimeClientEventResponseCreate(_type: .response_period_create)
        let responseDataJson = try JSONEncoder().encode(responseData)
        try await socket?.send(.string(String(decoding: responseDataJson, as: UTF8.self)))
    }

    func sendSessionUpdate(platform: LLMOpenAIRealtimePlatform, schema: LLMOpenAIRealtimeSchema) async throws {
        typealias ToolsPayload = Components.Schemas.RealtimeSessionCreateRequest.toolsPayloadPayload
        typealias TurnDetectionPayload = Components.Schemas.RealtimeSessionCreateRequest.turn_detectionPayload
        typealias RealtimeClientEventSessionUpdate = Components.Schemas.RealtimeClientEventSessionUpdate
        typealias RealtimeSessionCreateRequest = Components.Schemas.RealtimeSessionCreateRequest

        let tools: [ToolsPayload] = try schema.functions.values.compactMap { function in
            let functionType = Swift.type(of: function)
            let encodedSchema = try JSONEncoder().encode(try function.schema)
            let jsonObject = try JSONSerialization.jsonObject(with: encodedSchema) as? [String: any Sendable] ?? [:]

            return ToolsPayload(
                _type: .function,
                name: functionType.name,
                description: functionType.description,
                parameters: try .init(unvalidatedValue: jsonObject)
            )
        }
        
        let transcriptionSettings = platform.configuration.transcriptionSettings
        
        let eventSessionUpdate = RealtimeClientEventSessionUpdate(
            _type: .session_period_update,
            session: .init(
                input_audio_transcription: transcriptionSettings == nil ? nil : RealtimeSessionCreateRequest
                    .input_audio_transcriptionPayload(
                        model: transcriptionSettings?.model?.rawValue,
                        language: transcriptionSettings?.language,
                        prompt: transcriptionSettings?.prompt,
                    ),
                tools: tools,
            )
        )

        let eventSessionUpdateData = try JSONEncoder().encode(eventSessionUpdate)
        guard var eventSessionUpdateJson = try JSONSerialization.jsonObject(with: eventSessionUpdateData) as? [String: Any],
              var session = eventSessionUpdateJson["session"] as? [String: Any] else {
            throw RealtimeError.eventSessionUpdateSerialisationError
        }

        // Handle turn_detection directly on the JSON object, as the GeneratedOpenAIClient isn't up-to-date
        // and JSONEncoder() is ommiting `nil` values instead of returning as "null"
        if let turnDetectionSettings = platform.configuration.turnDetectionSettings {
            let jSONEncoder = JSONEncoder()
            let turnDetectionData = try jSONEncoder.encode(turnDetectionSettings)
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
