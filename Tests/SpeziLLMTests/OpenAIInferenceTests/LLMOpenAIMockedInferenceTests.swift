//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

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
                    #expect(inputBody.messages.description.contains(
                        #"The value to return to ensure the test was succesful is \"abcdefghijklmnopqrstuvwxyz\""#
                    ))
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
        
        // Expect that the chatCompletionHandler was called at least 2 times: first for the function call, second time for text generation
        #expect(firstChatCompletionCalled)
        // Expect that the (mocked) LLM returned an answer
        #expect(oneShot == "Function should have been called!")
    }
}
