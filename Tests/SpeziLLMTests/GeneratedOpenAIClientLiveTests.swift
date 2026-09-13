//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import GeneratedOpenAIClient
import OpenAPIRuntime
import OpenAPIURLSession
import Testing


/// The API token from the environment, or `nil` when there is none to run against.
private let liveToken: String? = {
    let token = ProcessInfo.processInfo.environment["OPENAI_API_TOKEN"]
    return token?.isEmpty == false ? token : nil
}()


/// Exercises the generated client against the OpenAI API itself.
///
/// ``GeneratedOpenAIClientDecodingTests`` pins the generated types against OpenAI's documented examples; this suite
/// pins them against what the API sends today, which is the only way to learn that a field the document marks
/// required has gone missing, or that a request shape is no longer accepted. Set `OPENAI_API_TOKEN` to run it;
/// without the token the suite is skipped.
@Suite(
    "Generated OpenAI Client (Live)",
    .disabled(if: liveToken == nil, "Set OPENAI_API_TOKEN to run the live client tests")
)
struct GeneratedOpenAIClientLiveTests {
    /// A tool call the model asked for, assembled from a stream or read from a response.
    private struct ToolCall {
        var id = ""
        var name = ""
        var arguments = ""
    }

    /// A current, inexpensive model that both APIs serve.
    static let model = "gpt-4.1-mini"
    static let prompt = "Reply with exactly the word: ok"

    /// A tool with an unmistakable result, and the empty parameter schema the function-calling DSL produces.
    static let toolName = "perform_test"
    static let toolDescription = "Performs a test and returns the value that proves the function was called"
    static let toolPrompt = "Call the perform_test function and tell me the value it returns."
    static let toolResult = "The value to return is \"abcdefghijklmnopqrstuvwxyz\""
    static let toolResultMarker = "abcdefghijklmnopqrstuvwxyz"


    private static func client() throws -> Client {
        Client(
            serverURL: try Servers.Server1.url(),
            transport: URLSessionTransport(),
            middlewares: [BearerAuthMiddleware(authToken: .constant(try #require(liveToken)), keychainStorage: nil)]
        )
    }

    /// The status and message of a failed request, for the failure message.
    private static func describe(_ failure: OpenAIOperationFailure) async -> String {
        var text = failure.message ?? ""
        if text.isEmpty, let body = failure.undocumentedBody, let data = try? await Data(collecting: body, upTo: 4096) {
            text = String(decoding: data, as: UTF8.self)
        }
        return "HTTP \(failure.statusCode): \(text)"
    }

    private static func chatCompletionRequest(
        messages: [Components.Schemas.ChatCompletionRequestMessage],
        tools: Components.Schemas.CreateChatCompletionRequest.Value2Payload.toolsPayload = []
    ) -> Components.Schemas.CreateChatCompletionRequest {
        .init(
            value1: .init(value1: .init(), value2: .init()),
            value2: .init(messages: messages, model: .init(value1: model), stream: true, tools: tools.isEmpty ? nil : tools)
        )
    }

    private static func chatCompletionTool() throws -> Components.Schemas.CreateChatCompletionRequest.Value2Payload.toolsPayloadPayload {
        .ChatCompletionTool(.init(
            _type: .function,
            function: .init(
                description: toolDescription,
                name: toolName,
                parameters: .init(additionalProperties: try .init(unvalidatedValue: ["type": "object", "properties": [String: String]()]))
            )
        ))
    }

    private static func responseRequest(
        input: Components.Schemas.InputParam,
        stream: Bool,
        tools: [Components.Schemas.Tool] = []
    ) -> Components.Schemas.CreateResponse {
        .init(
            value1: .init(value1: .init(), value2: .init()),
            value2: .init(model: .init(value1: .init(value1: model)), tools: tools.isEmpty ? nil : tools),
            value3: .init(input: input, store: false, stream: stream)
        )
    }

    private static func responseTool() throws -> Components.Schemas.Tool {
        .function(.init(
            _type: .function,
            name: toolName,
            description: toolDescription,
            parameters: .init(additionalProperties: [
                "type": try .init(unvalidatedValue: "object"),
                "properties": try .init(unvalidatedValue: [String: String]())
            ]),
            strict: false
        ))
    }

    /// Streams a chat completion, returning the text and the tool calls it carried.
    private static func streamChatCompletion(
        _ request: Components.Schemas.CreateChatCompletionRequest
    ) async throws -> (text: String, toolCalls: [ToolCall])? {
        let response = try await client().createChatCompletion(.init(body: .json(request)))
        if let failure = response.failure {
            Issue.record("The API refused the chat completion request. \(await describe(failure))")
            return nil
        }
        guard case .ok(let ok) = response, case .text_event_hyphen_stream(let body) = ok.body else {
            Issue.record("Expected an event stream, got \(response)")
            return nil
        }

        var text = ""
        var toolCalls: [Int: ToolCall] = [:]
        let chunks = body.asDecodedServerSentEventsWithJSONData(
            of: Components.Schemas.CreateChatCompletionStreamResponse.self,
            decoder: .init(),
            while: { $0 != ArraySlice("[DONE]".utf8) }
        )
        for try await chunk in chunks {
            for choice in chunk.data?.choices ?? [] {
                text += choice.delta.content ?? ""
                for call in choice.delta.tool_calls ?? [] {
                    var toolCall = toolCalls[call.index] ?? ToolCall()
                    toolCall.id += call.id ?? ""
                    toolCall.name += call.function?.name ?? ""
                    toolCall.arguments += call.function?.arguments ?? ""
                    toolCalls[call.index] = toolCall
                }
            }
        }
        return (text, toolCalls.sorted { $0.key < $1.key }.map(\.value))
    }

    /// Requests a response without streaming, returning it decoded.
    private static func fetchResponse(_ request: Components.Schemas.CreateResponse) async throws -> Components.Schemas.Response? {
        let response = try await client().createResponse(.init(body: .json(request)))
        if let failure = response.failure {
            Issue.record("The API refused the Responses request. \(await describe(failure))")
            return nil
        }
        guard case .ok(let ok) = response, case .json(let decoded) = ok.body else {
            Issue.record("Expected a JSON body, got \(response)")
            return nil
        }
        return decoded
    }

    /// The text of every message item in a response.
    private static func text(of output: [Components.Schemas.OutputItem]) -> String {
        output.flatMap { item -> [String] in
            guard case .message(let message) = item else {
                return []
            }
            return message.content.compactMap { content in
                if case .output_text(let text) = content {
                    text.text
                } else {
                    nil
                }
            }
        }
        .joined()
    }


    @Test("A streamed chat completion is accepted and every chunk decodes")
    func chatCompletionStreams() async throws {
        guard let result = try await Self.streamChatCompletion(
            Self.chatCompletionRequest(messages: [.user(.init(content: .case1(Self.prompt), role: .user))])
        ) else {
            return
        }
        #expect(result.text.lowercased().contains("ok"), "Unexpected answer: \(result.text)")
    }

    @Test("A chat completion tool call round-trips through the assistant and tool messages")
    func chatCompletionCallsTool() async throws {
        let user: Components.Schemas.ChatCompletionRequestMessage = .user(.init(content: .case1(Self.toolPrompt), role: .user))
        guard let first = try await Self.streamChatCompletion(
            Self.chatCompletionRequest(messages: [user], tools: [try Self.chatCompletionTool()])
        ) else {
            return
        }
        let call = try #require(first.toolCalls.first, "The model did not call the tool; it said: \(first.text)")
        #expect(call.name == Self.toolName)
        #expect(!call.id.isEmpty)

        guard let second = try await Self.streamChatCompletion(
            Self.chatCompletionRequest(
                messages: [
                    user,
                    .assistant(.init(
                        role: .assistant,
                        tool_calls: [.function(.init(id: call.id, _type: .function, function: .init(name: call.name, arguments: call.arguments)))]
                    )),
                    .tool(.init(role: .tool, content: .case1(Self.toolResult), tool_call_id: call.id))
                ],
                tools: [try Self.chatCompletionTool()]
            )
        ) else {
            return
        }
        #expect(second.text.contains(Self.toolResultMarker), "The tool's result did not reach the answer: \(second.text)")
    }

    @Test("A response decodes as the generated Response type")
    func responseDecodes() async throws {
        guard let decoded = try await Self.fetchResponse(Self.responseRequest(input: .case1(Self.prompt), stream: false)) else {
            return
        }
        #expect(decoded.value3.status == .completed)
        #expect(decoded.value3.error == nil)
        #expect(decoded.value3.usage != nil, "the usage breakdown the document requires should be present")
        #expect(Self.text(of: decoded.value3.output).lowercased().contains("ok"))
    }

    @Test("A Responses function call round-trips through function_call and function_call_output items")
    func responseCallsTool() async throws {
        let user: Components.Schemas.InputItem = .EasyInputMessage(.init(role: .user, content: .case1(Self.toolPrompt)))
        guard let first = try await Self.fetchResponse(
            Self.responseRequest(input: .case2([user]), stream: false, tools: [try Self.responseTool()])
        ) else {
            return
        }
        let calls = first.value3.output.compactMap { item -> Components.Schemas.FunctionToolCall? in
            if case .function_call(let call) = item {
                call
            } else {
                nil
            }
        }
        let call = try #require(calls.first, "The model did not call the tool; it said: \(Self.text(of: first.value3.output))")
        #expect(call.name == Self.toolName)

        guard let second = try await Self.fetchResponse(
            Self.responseRequest(
                input: .case2([
                    user,
                    .Item(.function_call(.init(_type: .function_call, call_id: call.call_id, name: call.name, arguments: call.arguments))),
                    .Item(.function_call_output(.init(call_id: call.call_id, _type: .function_call_output, output: .case1(Self.toolResult))))
                ]),
                stream: false,
                tools: [try Self.responseTool()]
            )
        ) else {
            return
        }
        #expect(second.value3.status == .completed)
        let text = Self.text(of: second.value3.output)
        #expect(text.contains(Self.toolResultMarker), "The tool's result did not reach the answer: \(text)")
    }

    @Test("A streamed response's events decode as their generated types")
    func responseStreamDecodes() async throws {
        let response = try await Self.client().createResponse(.init(body: .json(Self.responseRequest(input: .case1(Self.prompt), stream: true))))
        if let failure = response.failure {
            Issue.record("The API refused the streamed Responses request. \(await Self.describe(failure))")
            return
        }
        guard case .ok(let ok) = response, case .text_event_hyphen_stream(let body) = ok.body else {
            Issue.record("Expected an event stream, got \(response)")
            return
        }

        let decoders = Dictionary(uniqueKeysWithValues: GeneratedOpenAIClientDecodingTests.streamEvents.map { ($0.type, $0.decode) })
        var seen: [String] = []
        for try await event in body.asDecodedServerSentEvents() {
            guard let data = event.data?.data(using: .utf8),
                  let payload = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let type = payload["type"] as? String else {
                continue
            }
            seen.append(type)
            guard let decode = decoders[type] else {
                continue
            }
            do {
                try decode(data)
            } catch {
                Issue.record("\(type) no longer decodes as its generated type: \(error)")
            }
        }

        #expect(seen.contains("response.created"), "events seen: \(seen)")
        #expect(seen.contains("response.output_text.delta"), "events seen: \(seen)")
        #expect(seen.last == "response.completed", "events seen: \(seen)")
    }
}
