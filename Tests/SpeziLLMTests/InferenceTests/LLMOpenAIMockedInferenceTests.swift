//
//  Test.swift
//  SpeziLLM
//
//  Created by Sébastien Letzelter on 12.03.25.
//

import GeneratedOpenAIClient
import OpenAPIRuntime
@testable import Spezi
@testable import SpeziLLM
@testable import SpeziLLMOpenAI
import SwiftUI
import Testing


@Suite("LLM OpenAI Inference Tests (Mocked API)")
class LLMOpenAIMockedInferenceTests: LLMOpenAIInferenceTests {

    // MARK: Mock Chat Client

    final class MockChatClient: LLMOpenAIChatClientProtocol {
        var retrieveModelHandler: ((GeneratedOpenAIClient.Operations.retrieveModel.Input) async throws ->
                                   GeneratedOpenAIClient.Operations.retrieveModel.Output)?

        var createChatCompletionHandler: ((Operations.createChatCompletion.Input) async throws ->
                                          Operations.createChatCompletion.Output)?
        
        func retrieveModel(_ input: GeneratedOpenAIClient.Operations.retrieveModel.Input) async throws ->
            GeneratedOpenAIClient.Operations.retrieveModel.Output {
            guard let handler = retrieveModelHandler else {
                fatalError("Mock handler not set!")
            }
            return try await handler(input)
        }

        
        func createChatCompletion(_ input: Operations.createChatCompletion.Input) async throws -> Operations.createChatCompletion.Output {
            guard let handler = createChatCompletionHandler else {
                fatalError("Mock handler not set!")
            }
            return try await handler(input)
        }
    }
    
    struct ChatResponseBuilder {
        static let responseChunkId = UUID().uuidString;
        static let responseTimestamp = Int(Date().timeIntervalSince1970)
        
        let createMockChatResponse: (String) throws -> String = { message in
            String(decoding: try JSONEncoder().encode(
                Components.Schemas.CreateChatCompletionStreamResponse(
                    id: ChatResponseBuilder.responseChunkId,
                    choices: ([
                        .init(
                            delta: .init(content: message, role: .assistant),
                            logprobs: .none,
                            finish_reason: nil,
                            index: 0
                        )
                    ]),
                    created: ChatResponseBuilder.responseTimestamp,
                    model: "spezi-mock",
                    object: .chat_period_completion_period_chunk
                )
            ), as: UTF8.self)
        }

        let createMockFunctionCallResponse: (String, String) throws -> String = { name, arguments in
            String(decoding: try JSONEncoder().encode(
                Components.Schemas.CreateChatCompletionStreamResponse(
                    id: ChatResponseBuilder.responseChunkId,
                    choices: ([
                        .init(
                            delta: .init(content: .none, tool_calls: [.init(index: 0, id: UUID().uuidString, function: .init(name: name, arguments: arguments))]),
                            logprobs: .none,
                            finish_reason: nil,
                            index: 0
                        )
                    ]),
                    created: ChatResponseBuilder.responseTimestamp,
                    model: "spezi-mock",
                    object: .chat_period_completion_period_chunk
                )
            ), as: UTF8.self)
        }
        
        private(set) var events: [String] = []
        
        mutating func append(text: String) throws {
            try events.append("data: \(createMockChatResponse(text))\n\n")
        }

        mutating func append(functionName: String, arguments: String) throws {
            try events.append("data: \(createMockFunctionCallResponse(functionName, arguments))\n\n")
        }

        mutating func done() {
            events.append("data: [DONE]\n\n")
        }
        
        func toChatOutput() -> Operations.createChatCompletion.Output {
            let byteChunks = events.map { ArraySlice<UInt8>($0.utf8) }

            let stream = AsyncStream<ArraySlice<UInt8>> { continuation in
                for chunk in byteChunks {
                    continuation.yield(chunk)
                }
                continuation.finish()
            }
            
            let body = HTTPBody(stream,length: .unknown)

            return .ok(.init(body: .text_event_hyphen_stream(body)))
        }
    }
    
    // MARK: LLM Initialisation

    @MainActor
    private func initTestLLMSession(_ schema: LLMOpenAISchema) throws -> LLMOpenAISession {
        let llmOpenAIPlatform = LLMOpenAIPlatform(configuration: LLMOpenAIPlatformConfiguration(apiToken: "mocked-token"))

        let runner = LLMRunner { llmOpenAIPlatform }
        try DependencyManager([runner]).resolve()
        runner.configure()

        return llmOpenAIPlatform.callAsFunction(with: schema)
    }
    
    // MARK: Tests
    
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

        var firstChatCompletionCalled = false
        mockClient.createChatCompletionHandler = { input in
            var builder = ChatResponseBuilder()

            if !firstChatCompletionCalled {
                try builder.append(functionName: LLMOpenAITestFunction.name, arguments: "{}")
                builder.done()
                firstChatCompletionCalled = true
            } else {
                if case let .json(inputBody) = input.body {
                    // Expect to find the function call's result added in the input
                    #expect(inputBody.messages.description.contains(#"The value to return to ensure the test was succesful is \"abcdefghijklmnopqrstuvwxyz\""#))
                } else {
                    Issue.record("Failed to parse JSON input body")
                }

                try builder.append(text: "Function should have been called!")
                builder.done()
            }

            return builder.toChatOutput()
        }
        
        // Execute the mocked LLM
        var oneShot = ""
        for try await stringPiece in try await llmSession.generate() {
            oneShot.append(stringPiece)
        }
        
        // Expect that the chatCompletionHandler was called at least 2 times
        #expect(firstChatCompletionCalled)
        // Expect that the (mocked) LLM returned an answer
        #expect(oneShot == "Function should have been called!")
    }
}
