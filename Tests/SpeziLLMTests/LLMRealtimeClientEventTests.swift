//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziLLMOpenAI
@testable import SpeziLLMOpenAIRealtime
import Testing


/// Pins the wire shape of the Realtime client events that are defined locally rather than generated.
@Suite("Realtime Client Events")
struct LLMRealtimeClientEventTests {
    private static func json(_ value: some Encodable) throws -> [String: Any] {
        try #require(try JSONSerialization.jsonObject(with: JSONEncoder().encode(value)) as? [String: Any])
    }

    @Test("Turning turn detection off is spelled as an explicit null")
    func sessionUpdateWithoutTurnDetection() throws {
        let event = LLMRealtimeSessionUpdateEvent(
            session: .init(
                instructions: "Be brief.",
                voice: "alloy",
                inputAudioTranscription: .init(model: "whisper-1", language: nil, prompt: nil),
                turnDetection: nil,
                tools: []
            )
        )

        let json = try Self.json(event)
        #expect(json["type"] as? String == "session.update")
        let session = try #require(json["session"] as? [String: Any])
        #expect(session["instructions"] as? String == "Be brief.")
        #expect(session["voice"] as? String == "alloy")
        #expect(session["turn_detection"] is NSNull, "nil must reach the wire as null, which is how the API turns it off")
        #expect((session["tools"] as? [Any])?.isEmpty == true)
        let transcription = try #require(session["input_audio_transcription"] as? [String: Any])
        #expect(transcription["model"] as? String == "whisper-1")
        #expect(transcription["language"] == nil)
    }

    @Test("Turn detection settings and tools are carried through")
    func sessionUpdateWithTurnDetection() throws {
        let event = LLMRealtimeSessionUpdateEvent(
            session: .init(
                instructions: nil,
                voice: nil,
                inputAudioTranscription: nil,
                turnDetection: .server(.init()),
                tools: [.init(name: "perform_test", description: "A test", parameters: try .init(unvalidatedValue: ["type": "object"]))]
            )
        )

        let session = try #require(try Self.json(event)["session"] as? [String: Any])
        #expect(session["instructions"] == nil)
        #expect(session["input_audio_transcription"] == nil)
        let turnDetection = try #require(session["turn_detection"] as? [String: Any])
        #expect(turnDetection["type"] as? String == "server_vad")
        let tool = try #require((session["tools"] as? [[String: Any]])?.first)
        #expect(tool["type"] as? String == "function")
        #expect(tool["name"] as? String == "perform_test")
        #expect((tool["parameters"] as? [String: Any])?["type"] as? String == "object")
    }

    @Test("Conversation items carry the beta shape")
    func conversationItems() throws {
        let message = try Self.json(LLMRealtimeConversationItemCreateEvent(item: .userMessage(text: "Hi")))
        #expect(message["type"] as? String == "conversation.item.create")
        let messageItem = try #require(message["item"] as? [String: Any])
        #expect(messageItem["type"] as? String == "message")
        #expect(messageItem["role"] as? String == "user")
        let content = try #require((messageItem["content"] as? [[String: Any]])?.first)
        #expect(content["type"] as? String == "input_text")
        #expect(content["text"] as? String == "Hi")

        let output = try Self.json(LLMRealtimeConversationItemCreateEvent(item: .functionCallOutput(callId: "call_1", output: "42")))
        let outputItem = try #require(output["item"] as? [String: Any])
        #expect(outputItem["type"] as? String == "function_call_output")
        #expect(outputItem["call_id"] as? String == "call_1")
        #expect(outputItem["output"] as? String == "42")
    }

    @Test("A session update is built from the schema's parameters and functions")
    func sessionUpdateFromSchema() throws {
        let schema = LLMOpenAIRealtimeSchema(
            parameters: .init(
                modelType: .gptRealtime,
                systemPrompt: "Be brief.",
                turnDetectionSettings: nil,
                transcriptionSettings: .init(model: .whisper1, prompt: "Medical terms"),
                voice: .verse
            )
        ) {
            LLMOpenAIInferenceTests.LLMOpenAITestFunction()
        }

        let session = try #require(try Self.json(try LLMRealtimeSessionUpdateEvent(schema: schema))["session"] as? [String: Any])
        #expect(session["instructions"] as? String == "Be brief.")
        #expect(session["voice"] as? String == "verse")
        #expect(session["turn_detection"] is NSNull)
        let transcription = try #require(session["input_audio_transcription"] as? [String: Any])
        #expect(transcription["model"] as? String == "whisper-1")
        #expect(transcription["prompt"] as? String == "Medical terms")
        #expect(transcription["language"] == nil)
        let tool = try #require((session["tools"] as? [[String: Any]])?.first)
        #expect(tool["type"] as? String == "function")
        #expect(tool["name"] as? String == "perform_test")
        #expect((tool["parameters"] as? [String: Any])?["type"] as? String == "object")
    }
}
