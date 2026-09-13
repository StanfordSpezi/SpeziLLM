//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable file_types_order

import Foundation
import OpenAPIRuntime
import SpeziLLMOpenAI


// The two client events of the Realtime API's beta protocol that the generated client no longer describes.
//
// The OpenAI OpenAPI document only carries the general-availability shapes of these events, while this target still
// speaks the beta protocol it was written against. Defining the beta shapes here keeps the bytes on the wire
// unchanged until the target moves to the GA protocol. The remaining client events and the server events have the
// same shape under both protocols and stay generated.
//
// OpenAI has since stopped serving the beta protocol altogether: the endpoint answers a beta connection with
// `beta_api_shape_disabled` before any event is sent, and accepts the GA session shape without the beta header.
// Moving the target to the GA protocol replaces this file.


/// The `session.update` event, configuring the session after the socket has opened.
struct LLMRealtimeSessionUpdateEvent: Encodable {
    struct Session: Encodable {
        private enum ToolCodingKeys: String, CodingKey {
            case type
            case name
            case description
            case parameters
        }

        struct Tool: Encodable {
            let name: String
            let description: String
            let parameters: OpenAPIObjectContainer

            func encode(to encoder: any Encoder) throws {
                var container = encoder.container(keyedBy: ToolCodingKeys.self)
                try container.encode("function", forKey: .type)
                try container.encode(name, forKey: .name)
                try container.encode(description, forKey: .description)
                try container.encode(parameters, forKey: .parameters)
            }
        }

        struct InputAudioTranscription: Encodable {
            let model: String?
            let language: String?
            let prompt: String?
        }

        private enum CodingKeys: String, CodingKey {
            case instructions
            case voice
            case inputAudioTranscription = "input_audio_transcription"
            case turnDetection = "turn_detection"
            case tools
        }

        let instructions: String?
        let voice: String?
        let inputAudioTranscription: InputAudioTranscription?
        /// `nil` is sent as an explicit `null`, which is how the API is told to turn turn detection off.
        let turnDetection: LLMRealtimeTurnDetectionSettings?
        let tools: [Tool]

        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(instructions, forKey: .instructions)
            try container.encodeIfPresent(voice, forKey: .voice)
            try container.encodeIfPresent(inputAudioTranscription, forKey: .inputAudioTranscription)
            if let turnDetection {
                try container.encode(turnDetection, forKey: .turnDetection)
            } else {
                try container.encodeNil(forKey: .turnDetection)
            }
            try container.encode(tools, forKey: .tools)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case session
    }

    let session: Session


    /// The session update that configures a session the way the schema describes it.
    init(schema: LLMOpenAIRealtimeSchema) throws {
        let encoder = JSONEncoder()
        let tools: [Session.Tool] = try schema.functions.values.map { function in
            let functionType = Swift.type(of: function)
            let encodedSchema = try encoder.encode(try function.schema)
            let parameters = try JSONSerialization.jsonObject(with: encodedSchema) as? [String: any Sendable] ?? [:]
            return Session.Tool(
                name: functionType.name,
                description: functionType.description,
                parameters: try .init(unvalidatedValue: parameters)
            )
        }
        let transcriptionSettings = schema.parameters.transcriptionSettings

        self.session = Session(
            instructions: schema.parameters.systemPrompt,
            voice: schema.parameters.voice?.rawValue,
            inputAudioTranscription: transcriptionSettings.map { settings in
                .init(
                    model: settings.model.rawValue,
                    language: settings.language?.identifier,
                    prompt: settings.prompt
                )
            },
            turnDetection: schema.parameters.turnDetectionSettings,
            tools: tools
        )
    }

    init(session: Session) {
        self.session = session
    }


    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("session.update", forKey: .type)
        try container.encode(session, forKey: .session)
    }
}


/// The `conversation.item.create` event, adding an item to the conversation.
struct LLMRealtimeConversationItemCreateEvent: Encodable {
    enum Item: Encodable {
        /// A text message from the user.
        case userMessage(text: String)
        /// The result of a function the model asked to be called.
        case functionCallOutput(callId: String, output: String)

        private enum TextContentCodingKeys: String, CodingKey {
            case type
            case text
        }

        private struct TextContent: Encodable {
            let text: String

            func encode(to encoder: any Encoder) throws {
                var container = encoder.container(keyedBy: TextContentCodingKeys.self)
                try container.encode("input_text", forKey: .type)
                try container.encode(text, forKey: .text)
            }
        }

        private enum CodingKeys: String, CodingKey {
            case type
            case role
            case content
            case callId = "call_id"
            case output
        }

        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .userMessage(let text):
                try container.encode("message", forKey: .type)
                try container.encode("user", forKey: .role)
                try container.encode([TextContent(text: text)], forKey: .content)
            case let .functionCallOutput(callId, output):
                try container.encode("function_call_output", forKey: .type)
                try container.encode(callId, forKey: .callId)
                try container.encode(output, forKey: .output)
            }
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case item
    }

    let item: Item

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("conversation.item.create", forKey: .type)
        try container.encode(item, forKey: .item)
    }
}
