//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import GeneratedOpenAIClient
import OpenAPIRuntime
@testable import SpeziLLM
@testable import SpeziLLMOpenAI
import Testing


@Suite("LLM OpenAI Inference Tests (Mocked API)")
class LLMOpenAIMockedInferenceTests: LLMOpenAIInferenceTests {
    @MainActor
    @Test
    func testMockedOpenAIInference() async throws {
        let schema = LLMOpenAISchema(
            parameters: .init(modelType: .gpt4o_mini)
        ) { }
        
        var context = LLMContext()
        context.append(userInput: "Hello!")
        
        let mockClient = MockChatClient()
        mockClient.createChatCompletionHandler = { _ in
            var builder = ChatResponseBuilder()
            try builder.append(text: "Hello ")
            try builder.append(text: "world!")
            builder.done()
            
            return builder.toChatOutput()
        }
        
        let llmSession = try initTestLLMSession(schema)
        llmSession.context = context
        llmSession.wrappedClient = mockClient
        
        var oneShot = ""
        for try await stringPiece in try await llmSession.generate() {
            oneShot.append(stringPiece)
        }
        
        #expect(oneShot == "Hello world!")
    }
    
    @MainActor
    @Test
    func testMockedOpenAIFunctionCalling() async throws {
        var context = LLMContext()
        context.append(userInput: "Hello!")
        
        let mockClient = MockChatClient()
        let schema = LLMOpenAISchema(
            parameters: .init(modelType: .gpt4o_mini)
        ) {
            LLMOpenAITestFunction()
        }
        
        let llmSession = try initTestLLMSession(schema)
        llmSession.context = context
        llmSession.wrappedClient = mockClient
        
        var chatCompletionCalls = 0
        mockClient.createChatCompletionHandler = { input in
            var builder = ChatResponseBuilder()
            
            if chatCompletionCalls == 0 {
                try builder.append(functionName: LLMOpenAITestFunction.name, arguments: "{}")
                builder.done()
            } else {
                if case let .json(inputBody) = input.body {
                    // Expect to find the function call's result added in the input
                    #expect(inputBody.value2.messages.description.contains(
                        #"The value to return to ensure the test was succesful is \"abcdefghijklmnopqrstuvwxyz\""#
                    ))
                } else {
                    Issue.record("Failed to parse JSON input body")
                }
                
                try builder.append(text: "Function should have been called!")
                builder.done()
            }
            
            chatCompletionCalls += 1
            return builder.toChatOutput()
        }
        
        var oneShot = ""
        for try await stringPiece in try await llmSession.generate() {
            oneShot.append(stringPiece)
        }
        
        // Expect that the chatCompletionHandler was called 2 times: first for the function call, second time for text generation
        #expect(chatCompletionCalls == 2, "Chat completion handler was not called twice")
        // Expect that the (mocked) LLM returned an answer
        #expect(oneShot == "Function should have been called!")
    }

    @Test("A documented rate limit surfaces as the quota error")
    func rateLimitIsQuotaError() async throws {
        try await expectGenerationFailure(
            .tooManyRequests(.init(body: .json(.init(error: .init(code: "rate_limit_exceeded", message: "Slow down", _type: "requests"))))),
            toBe: .insufficientQuota
        )
    }

    @Test("A documented outage surfaces as a generation error")
    func outageIsGenerationError() async throws {
        try await expectGenerationFailure(
            .serviceUnavailable(.init(body: .json(.init(error: .init(message: "Try again later", _type: "server_error"))))),
            toBe: .generationError
        )
    }

    @Test("An undocumented status keeps its mapping, body included")
    func undocumentedStatusKeepsMapping() async throws {
        try await expectGenerationFailure(
            .undocumented(statusCode: 401, .init(body: HTTPBody(#"{"error": {"message": "bad key"}}"#))),
            toBe: .invalidAPIToken
        )
    }

    /// Runs one generation against a client that answers with `response`, and checks the error the session reports.
    @MainActor
    private func expectGenerationFailure(_ response: Operations.createChatCompletion.Output, toBe expected: LLMOpenAIError) async throws {
        let mockClient = MockChatClient()
        mockClient.createChatCompletionHandler = { _ in response }

        let llmSession = try initTestLLMSession(LLMOpenAISchema(parameters: .init(modelType: .gpt4o_mini)))
        llmSession.context.append(userInput: "Hello!")
        llmSession.openAiClient = mockClient

        do {
            for try await _ in try await llmSession.generate() { }
            Issue.record("Expected \(expected) to be thrown")
        } catch let error as LLMOpenAIError {
            #expect(error == expected)
        }
    }
}
