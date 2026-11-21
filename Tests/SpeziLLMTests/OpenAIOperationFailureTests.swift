//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
@testable import GeneratedOpenAIClient
import OpenAPIRuntime
import Testing


/// Pins that every non-success output of the generated operations reduces to its status code and raw body.
@Suite("OpenAI Operation Failures")
struct OpenAIOperationFailureTests {
    @Test("Chat completion outputs reduce to their status")
    func chatCompletionOutputs() async throws {
        typealias Output = Operations.createChatCompletion.Output

        #expect(Output.ok(.init(body: .text_event_hyphen_stream(HTTPBody()))).failure == nil)

        let limited = try #require(Output.undocumented(statusCode: 429, .init(body: HTTPBody(#"{"error": {"message": "Slow down"}}"#))).failure)
        #expect(limited.statusCode == 429)
        #expect(await limited.message() == "Slow down")

        let odd = try #require(Output.undocumented(statusCode: 418, .init(body: HTTPBody("teapot"))).failure)
        #expect(odd.statusCode == 418)
        #expect(await odd.message() == "teapot")
    }

    @Test("Responses outputs reduce to their status")
    func responseOutputs() async throws {
        typealias Output = Operations.createResponse.Output

        #expect(Output.ok(.init(body: .text_event_hyphen_stream(HTTPBody()))).failure == nil)

        let down = try #require(Output.undocumented(statusCode: 503, .init()).failure)
        #expect(down.statusCode == 503)
        #expect(down.body == nil)
        #expect(await down.message() == nil)
    }

    @Test("Model retrieval outputs reduce to their status")
    func retrieveModelOutputs() async throws {
        typealias Output = Operations.retrieveModel.Output

        let model = Components.Schemas.Model(id: "gpt-4.1-mini", created: 0, object: .model, owned_by: "openai")
        #expect(Output.ok(.init(body: .json(model))).failure == nil)

        let missing = try #require(Output.undocumented(statusCode: 404, .init(body: HTTPBody(#"{"error": "model 'x' not found"}"#))).failure)
        #expect(missing.statusCode == 404)
        #expect(await missing.message() == "model 'x' not found")
    }

    @Test("The message is read from every common error body", arguments: [
        (#"{"error": {"message": "Incorrect API key", "type": "invalid_request_error"}}"#, "Incorrect API key"),
        (#"{"error": "model 'llama3' not found, try pulling it first"}"#, "model 'llama3' not found, try pulling it first"),
        (#"{"detail": "Not Found"}"#, #"{"detail": "Not Found"}"#),
        ("<html><body>502 Bad Gateway</body></html>\n", "<html><body>502 Bad Gateway</body></html>"),
        ("   ", nil)
    ])
    func messages(body: String, expected: String?) {
        #expect(OpenAIOperationFailure.message(from: Data(body.utf8)) == expected)
    }
}
