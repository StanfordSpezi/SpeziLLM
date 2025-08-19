//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import GeneratedOpenAIClient
import OpenAPIRuntime
import OpenAPIURLSession
import os
import SpeziChat
import SpeziKeychainStorage
import SpeziLLM

@Observable
public final class LLMOpenAIRealtimeSession: AudioCapableLLMSession, Sendable {
    /// A Swift Logger that logs important information from the ``LLMOpenAIRealtimeSession``.
    static let logger = Logger(subsystem: "edu.stanford.spezi", category: "SpeziLLMOpenAIRealtime")
    
    let platform: LLMOpenAIRealtimePlatform
    let schema: LLMOpenAIRealtimeSchema
    let keychainStorage: KeychainStorage
    
    @MainActor @ObservationIgnored var webSocketTask: URLSessionWebSocketTask?
        
    // Connection is isolated; it owns socket + loops + routing
    let connection = RealtimeConnection()


    @MainActor public var state: LLMState = .uninitialized
    @MainActor public var context: LLMContext = []

    /// Holds the currently generating continuations so that we can cancel them if required.
    let continuationHolder = LLMInferenceQueueContinuationHolder()
    
    /// Creates an instance of a ``LLMOpenAISession`` responsible for LLM inference.
    ///
    /// - Parameters:
    ///   - platform: Reference to the ``LLMOpenAIRealtimePlatform`` where the ``LLMOpenAIRealtimeSession`` is running on.
    ///   - schema: The configuration of the OpenAI LLM expressed by the ``LLMOpenAIRealtimeSchema``.
    ///   - keychainStorage: Reference to the `KeychainStorage` from `SpeziStorage` in order to securely persist the token.
    ///
    /// - Important: Only the ``LLMOpenAIRealtimePlatform`` should create an instance of ``LLMOpenAIRealtimeSession``.
    init(_ platform: LLMOpenAIRealtimePlatform, schema: LLMOpenAIRealtimeSchema, keychainStorage: KeychainStorage) {
        self.platform = platform
        self.schema = schema
        self.keychainStorage = keychainStorage
    }

    /// Generates the text results that get appended to the context, based on the text. And if you're listening to the stream via `listen()` then you'll also get the audio output
    /// Note that if you were speaking into the microphone until that point and sending that with appendUserAudio(), this also gets included when calling generate() here
    @discardableResult
    public func generate() async throws -> AsyncThrowingStream<String, any Error> {
        // 1. Send the relevant context as text to OpenAI
        // 2. Probably here we generate and return a new stream, which is active until the next response.done. The stream returns content += string deltas
        //    like LLMOpenAISession, so that it can be used inside ChatView.
        //
        // Listening to `self.event()` would probably be smart here, to avoid re-inventing the wheel.
        let (stream, _) = AsyncThrowingStream.makeStream(of: String.self)
        // TODO: Trigger setup only once
        let res = await setup()
        print("Setup succesfull: \(res)")
        
        return stream
    }
    
    /// Returns an audio stream (pcm16)  from chatGPT that you can listen to
    public func listen() -> AsyncThrowingStream<Data, any Error> {
        // Listening to `self.event()` would probably be smart here, to avoid re-inventing the wheel.
        // Always the same stream gets returned: no new stream gets created here
        AsyncThrowingStream { [connection] continuation in
            // Keep the task alive for the lifetime of the stream.
            let task = Task {
                do {
                    for try await event in connection.eventStream {
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
        try await connection.socket?.send(.string(String(decoding: eventDataJson, as: UTF8.self)))
    }
    
    /// Only used when having manual VAD: asks OpenAI to generate response event to obtain audio / transcripts
    func endUserTurn() async throws {
    }
    
    /// For very custom UIs: you can use `events()` which returns a stream with the actual OpenAI Realtime events
    func events() -> AsyncThrowingStream<RealtimeLLMEvent, any Error> {
        connection.eventStream
    }
    
    public func cancel() {
        print("Cancelling happens!")
        // cancel all currently generating continuations
        self.continuationHolder.cancelAll()
        
        Task.detached { [connection] in await connection.cancel() }
    }

    deinit {
        self.cancel()
    }
}

actor RealtimeConnection {
    typealias RealtimeClientEventSessionUpdate = Components.Schemas.RealtimeClientEventSessionUpdate

    enum RealtimeError: Error {
        case malformedUrlError
        case socketNotFoundError
        case openAIError
    }

    static let logger = Logger(subsystem: "edu.stanford.spezi", category: "SpeziLLMOpenAIRealtime")

    private var eventLoopTask: Task<Void, any Error>?

    // Connection stuff
    internal var socket: URLSessionWebSocketTask?
    private lazy var urlSession = URLSession(configuration: .default)

    // The important stream: event stream which gets sent in session.events()
    let eventStream: AsyncThrowingStream<RealtimeLLMEvent, any Error>
    let eventStreamContinuation: AsyncThrowingStream<RealtimeLLMEvent, any Error>.Continuation

    // Handling of the setup: only finish whenever the connection to API has been succesful
    private var readyContinuation: CheckedContinuation<Void, any Error>?
    private var didSignalReady = false

    init() {
        let (stream, continuation) = AsyncThrowingStream.makeStream(of: RealtimeLLMEvent.self)
        eventStream = stream
        eventStreamContinuation = continuation
    }
        
    func cancel() {
        print("ℹ️ RealtimeConnection: is getting cancelled")
        eventLoopTask?.cancel()
        eventLoopTask = nil

        socket?.cancel()
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
        eventLoopTask = Task { [weak self] in
            do {
                try await self?.eventLoop()
            } catch is CancellationError {
                // expected on cancel: ignore
                print("✅ runForever: Cancellation error")
            } catch {
                print("‼️ receiveLoop failed:", error)
            }
        }
        // Await until we obtain session.created from OpenAI
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            readyContinuation = continuation
        }
    }
    
    // swiftlint:disable function_body_length cyclomatic_complexity
    /// Contains the whole event loop
    private func eventLoop() async throws {
        guard let socket = socket else {
            throw RealtimeError.socketNotFoundError
        }
        while !Task.isCancelled {
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
                        eventSessionCreated(messageDict)
                    case "response.audio.delta":
                        guard let deltaPcmData = Data(base64Encoded: messageDict["delta"] as? String ?? "") else {
                            continue
                        }
                        let llmEvent = RealtimeLLMEvent.audioDelta(deltaPcmData)
                        eventStreamContinuation.yield(llmEvent)
                    case "response.audio.done":
//                        guard let deltaPcmData = Data(base64Encoded: messageDict["delta"] as? String ?? "") else {
//                            continue
//                        }
//                        let llmEvent = RealtimeLLMEvent.audioDelta(deltaPcmData)
//                        eventStreamContinuation.yield(llmEvent)
                        print("audio.done: ", messageDict)
                    case "response.audio_transcript.delta":
                        let transcript = messageDict["delta"] as? String ?? ""
                        let llmEvent = RealtimeLLMEvent.assistantTranscriptDelta(transcript)
                        eventStreamContinuation.yield(llmEvent)
                    case "response.audio_transcript.done":
                        let transcript = messageDict["transcript"] as? String ?? ""
                        let llmEvent = RealtimeLLMEvent.assistantTranscriptDone(transcript)
                        eventStreamContinuation.yield(llmEvent)
                    case "conversation.item.input_audio_transcription.delta":
                        let transcript = messageDict["delta"] as? String ?? ""
                        let llmEvent = RealtimeLLMEvent.userTranscriptDelta(transcript)
                        eventStreamContinuation.yield(llmEvent)
                    case "conversation.item.input_audio_transcription.completed":
                        let transcript = messageDict["transcript"] as? String ?? ""
                        let llmEvent = RealtimeLLMEvent.userTranscriptDone(transcript)
                        eventStreamContinuation.yield(llmEvent)
                    case "input_audio_buffer.speech_started":
                        eventStreamContinuation.yield(RealtimeLLMEvent.speechStarted)
                    case "input_audio_buffer.speech_stopped":
                        eventStreamContinuation.yield(RealtimeLLMEvent.speechStopped)
                    case "response.content_part.added", "response.output_item.done", "response.done":
                        print(type)
                        print(messageDict)
                        print("------")
                    case "error":
                        eventError(messageDict)
                    default:
//                        print(type)
                        break
                    }
                }
            }
        }
        
        func eventSessionCreated(_ content: [String: Any]) {
            print("Session created!")
            print(content)
            Task {
                try await sendSessionUpdate()
            }
            readyContinuation?.resume(with: .success(()))
            readyContinuation = nil
        }
        
        func eventError(_ content: [String: Any]) {
            readyContinuation?.resume(with: .failure(RealtimeError.openAIError))
            readyContinuation = nil
            eventStreamContinuation.finish(throwing: RealtimeError.openAIError)
        }
    }

    func sendSessionUpdate() async throws {
        let eventSessionUpdate = RealtimeClientEventSessionUpdate(
            _type: .session_period_update,
            session: .init(
//                turn_detection: turnDetection,
//                tools: tools
                input_audio_transcription: Components.Schemas.RealtimeSessionCreateRequest
                    .input_audio_transcriptionPayload(model: "whisper-1")
            )
        )

        
        let eventSessionUpdateJson = try JSONEncoder().encode(eventSessionUpdate)
        try await socket?.send(.string(String(decoding: eventSessionUpdateJson, as: UTF8.self)))
        Self.logger.debug("Sent session update:\n\(String(decoding: eventSessionUpdateJson, as: UTF8.self))")
    }
    
}
