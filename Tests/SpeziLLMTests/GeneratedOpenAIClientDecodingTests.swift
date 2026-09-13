//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import GeneratedOpenAIClient
import Testing


/// Decodes the example payloads from OpenAI's API reference with the generated client types.
///
/// The payloads are the `x-oaiMeta` examples of the OpenAI OpenAPI document, which is to say the shapes the API
/// documents itself as sending. They pin two things a successful build cannot: that a union whose discriminator
/// OpenAI spells differently from the schema name binds on the wire value, and that a field the API sends as
/// `null` decodes at all. Either failure turns every real response into a generic decoding error.
@Suite("Generated OpenAI Client Decoding")
struct GeneratedOpenAIClientDecodingTests {
    /// One documented server-sent event, and the generated type it has to decode as.
    struct StreamEvent: Sendable, CustomStringConvertible {
        let type: String
        let decode: @Sendable (Data) throws -> Void

        var description: String {
            type
        }

        static func event<Event: Decodable>(_ type: String, as _: Event.Type) -> Self {
            Self(type: type) { data in
                _ = try JSONDecoder().decode(Event.self, from: data)
            }
        }
    }

    static let responses = ["text-input", "image-input", "file-input", "web-search", "file-search", "functions", "reasoning"]

    static let streamEvents: [StreamEvent] = [
        .event("response.created", as: Components.Schemas.ResponseCreatedEvent.self),
        .event("response.in_progress", as: Components.Schemas.ResponseInProgressEvent.self),
        .event("response.output_item.added", as: Components.Schemas.ResponseOutputItemAddedEvent.self),
        .event("response.content_part.added", as: Components.Schemas.ResponseContentPartAddedEvent.self),
        .event("response.output_text.delta", as: Components.Schemas.ResponseTextDeltaEvent.self),
        .event("response.output_text.done", as: Components.Schemas.ResponseTextDoneEvent.self),
        .event("response.output_text.annotation.added", as: Components.Schemas.ResponseOutputTextAnnotationAddedEvent.self),
        .event("response.content_part.done", as: Components.Schemas.ResponseContentPartDoneEvent.self),
        .event("response.output_item.done", as: Components.Schemas.ResponseOutputItemDoneEvent.self),
        .event("response.function_call_arguments.done", as: Components.Schemas.ResponseFunctionCallArgumentsDoneEvent.self),
        .event("response.reasoning_summary_part.added", as: Components.Schemas.ResponseReasoningSummaryPartAddedEvent.self),
        .event("response.reasoning_summary_text.delta", as: Components.Schemas.ResponseReasoningSummaryTextDeltaEvent.self),
        .event("response.reasoning_summary_text.done", as: Components.Schemas.ResponseReasoningSummaryTextDoneEvent.self),
        .event("response.refusal.delta", as: Components.Schemas.ResponseRefusalDeltaEvent.self),
        .event("response.refusal.done", as: Components.Schemas.ResponseRefusalDoneEvent.self),
        .event("response.completed", as: Components.Schemas.ResponseCompletedEvent.self),
        .event("response.incomplete", as: Components.Schemas.ResponseIncompleteEvent.self),
        .event("response.failed", as: Components.Schemas.ResponseFailedEvent.self),
        .event("error", as: Components.Schemas.ResponseErrorEvent.self)
    ]


    // MARK: - Fixtures

    private static func fixture(named name: String, in file: String) throws -> Data {
        let url = try #require(
            Bundle.module.url(forResource: file, withExtension: "json", subdirectory: "Fixtures"),
            "Missing fixture file \(file).json"
        )
        let fixtures = try #require(try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        let fixture = try #require(fixtures[name], "No fixture named \(name) in \(file).json")
        return try JSONSerialization.data(withJSONObject: updated(fixture))
    }

    private static func decode<Value: Decodable>(_ type: Value.Type, named name: String, in file: String) throws -> Value {
        try JSONDecoder().decode(type, from: fixture(named: name, in: file))
    }

    /// Brings a documented example up to date with the fields the API added after the example was written.
    ///
    /// The document marks these fields as required, and the API has sent them on every response since 2025, but
    /// OpenAI's reference examples predate them. Each is filled with the value the API sends when there is nothing
    /// to report, so the examples exercise the current schema rather than a historical one.
    private static func updated(_ value: Any) -> Any {
        switch value {
        case let object as [String: Any]:
            return addingUsageFields(to: addingResponseFields(to: addingOutputFields(to: object))).mapValues(updated)
        case let array as [Any]:
            return array.map(updated)
        default:
            return value
        }
    }

    private static func addingOutputFields(to object: [String: Any]) -> [String: Any] {
        var object = object
        let type = object["type"] as? String
        // Log probabilities accompany every piece of output text, on items and on the text stream events.
        if ["output_text", "response.output_text.delta", "response.output_text.done"].contains(type), object["logprobs"] == nil {
            object["logprobs"] = [] as [Any]
        }
        // A web search reports the action it took.
        if type == "web_search_call", object["action"] == nil {
            object["action"] = ["type": "search"]
        }
        // The reason a response stopped early was renamed after the example was written.
        if object["reason"] as? String == "max_tokens" {
            object["reason"] = "max_output_tokens"
        }
        return object
    }

    private static func addingResponseFields(to object: [String: Any]) -> [String: Any] {
        var object = object
        // Every stream event is numbered.
        if let type = object["type"] as? String, type.hasPrefix("response.") || type == "error", object["sequence_number"] == nil {
            object["sequence_number"] = 0
        }
        // A response object always reports its status and its tool-calling mode, and a message item its status.
        if object["object"] as? String == "response" {
            object["status"] = object["status"] ?? "completed"
            object["parallel_tool_calls"] = object["parallel_tool_calls"] ?? true
        }
        if object["type"] as? String == "message", object["role"] as? String == "assistant" {
            object["status"] = object["status"] ?? "completed"
        }
        return object
    }

    private static func addingUsageFields(to object: [String: Any]) -> [String: Any] {
        var object = object
        // Token usage is broken down on both sides, and the input breakdown gained a cache-write count.
        if object["input_tokens"] != nil {
            var details = object["input_tokens_details"] as? [String: Any] ?? [:]
            details["cached_tokens"] = details["cached_tokens"] ?? 0
            details["cache_write_tokens"] = details["cache_write_tokens"] ?? 0
            object["input_tokens_details"] = details
        }
        if object["output_tokens"] != nil, object["output_tokens_details"] == nil {
            object["output_tokens_details"] = ["reasoning_tokens": 0]
        }
        return object
    }


    // MARK: - Tests

    @Test("Every documented response decodes", arguments: responses)
    func decodesResponses(name: String) throws {
        let response = try Self.decode(Components.Schemas.Response.self, named: name, in: "OpenAIResponses")

        #expect(!response.value3.id.isEmpty)
        #expect(response.value3.status == .completed)
        #expect(!response.value3.output.isEmpty)
        // A completed response carries no error, which the API spells as an explicit `null`.
        #expect(response.value3.error == nil)
    }

    @Test("A cited answer binds its annotations on the wire's discriminator")
    func decodesCitations() throws {
        let response = try Self.decode(Components.Schemas.Response.self, named: "web-search", in: "OpenAIResponses")

        let annotations = response.value3.output.flatMap { item -> [Components.Schemas.Annotation] in
            guard case .message(let message) = item else {
                return []
            }
            return message.content.flatMap { content -> [Components.Schemas.Annotation] in
                guard case .output_text(let text) = content else {
                    return []
                }
                return text.annotations
            }
        }

        #expect(
            annotations.contains { annotation in
                if case .url_citation = annotation {
                    true
                } else {
                    false
                }
            },
            "The document sends `\"type\": \"url_citation\"`; the union has to bind on that value"
        )
    }

    @Test("A function call arrives as an output item of its own")
    func decodesFunctionCalls() throws {
        let response = try Self.decode(Components.Schemas.Response.self, named: "functions", in: "OpenAIResponses")

        guard case .function_call(let call) = try #require(response.value3.output.first) else {
            Issue.record("Expected a function_call item, got \(String(describing: response.value3.output.first))")
            return
        }
        #expect(!call.name.isEmpty)
        #expect(!call.call_id.isEmpty)
        #expect(!call.arguments.isEmpty)
    }

    @Test("Every documented stream event decodes as its own type", arguments: streamEvents)
    func decodesStreamEvents(event: StreamEvent) throws {
        try event.decode(try Self.fixture(named: event.type, in: "OpenAIResponseStreamEvents"))
    }
}
