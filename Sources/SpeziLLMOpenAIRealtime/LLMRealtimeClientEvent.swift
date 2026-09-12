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


// The two client events of the Realtime API's beta protocol that the generated client no longer describes.
//
// The OpenAI OpenAPI document only carries the general-availability shapes of these events, while this target still
// speaks the beta protocol it was written against. Defining the beta shapes here keeps the bytes on the wire
// unchanged until the target moves to the GA protocol. The remaining client events and the server events have the
// same shape under both protocols and stay generated.


/// The `session.update` event, configuring the session after the socket has opened.
struct LLMRealtimeSessionUpdateEvent: Encodable {
    struct Session: Encodable {
        struct Tool: Encodable {
            let type = "function"
            let name: String
            let description: String
            let parameters: OpenAPIObjectContainer
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

    let type = "session.update"
    let session: Session
}


/// The `conversation.item.create` event, adding an item to the conversation.
struct LLMRealtimeConversationItemCreateEvent: Encodable {
    enum Item: Encodable {
        /// A text message from the user.
        case userMessage(text: String)
        /// The result of a function the model asked to be called.
        case functionCallOutput(callId: String, output: String)

        private struct TextContent: Encodable {
            let type = "input_text"
            let text: String
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

    let type = "conversation.item.create"
    let item: Item
}
