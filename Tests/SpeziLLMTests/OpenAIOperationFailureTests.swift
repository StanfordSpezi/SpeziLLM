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
import Testing


/// Pins that every non-success output of the generated operations reduces to the status code the API answered with.
@Suite("OpenAI Operation Failures")
struct OpenAIOperationFailureTests {
    private static func rateLimited(_ message: String) -> Components.Responses.InferenceRateLimited {
        .init(body: .json(.init(error: .init(code: "rate_limit_exceeded", message: message, _type: "requests"))))
    }

    private static func unavailable(_ message: String) -> Components.Responses.InferenceServiceUnavailable {
        .init(body: .json(.init(error: .init(message: message, _type: "server_error"))))
    }

    @Test("Chat completion outputs reduce to their status")
    func chatCompletionOutputs() throws {
        typealias Output = Operations.createChatCompletion.Output

        #expect(Output.ok(.init(body: .text_event_hyphen_stream(HTTPBody()))).failure == nil)

        let limited = try #require(Output.tooManyRequests(Self.rateLimited("Slow down")).failure)
        #expect(limited.statusCode == 429)
        #expect(limited.message == "Slow down")

        let down = try #require(Output.serviceUnavailable(Self.unavailable("Later")).failure)
        #expect(down.statusCode == 503)
        #expect(down.message == "Later")

        let odd = try #require(Output.undocumented(statusCode: 418, .init(body: HTTPBody("teapot"))).failure)
        #expect(odd.statusCode == 418)
        #expect(odd.message == nil)
        #expect(odd.undocumentedBody != nil)
    }

    @Test("Responses outputs reduce to their status")
    func responseOutputs() throws {
        typealias Output = Operations.createResponse.Output

        #expect(Output.ok(.init(body: .text_event_hyphen_stream(HTTPBody()))).failure == nil)

        let limited = try #require(Output.tooManyRequests(Self.rateLimited("Slow down")).failure)
        #expect(limited.statusCode == 429)
        #expect(limited.message == "Slow down")

        let down = try #require(Output.serviceUnavailable(Self.unavailable("Later")).failure)
        #expect(down.statusCode == 503)
        #expect(down.message == "Later")

        let odd = try #require(Output.undocumented(statusCode: 500, .init()).failure)
        #expect(odd.statusCode == 500)
        #expect(odd.undocumentedBody == nil)
    }

    @Test("Model retrieval outputs reduce to their status")
    func retrieveModelOutputs() throws {
        typealias Output = Operations.retrieveModel.Output

        let model = Components.Schemas.Model(id: "gpt-4.1-mini", created: 0, object: .model, owned_by: "openai")
        #expect(Output.ok(.init(body: .json(model))).failure == nil)

        let missing = try #require(Output.undocumented(statusCode: 404, .init()).failure)
        #expect(missing.statusCode == 404)
        #expect(missing.message == nil)
    }
}
