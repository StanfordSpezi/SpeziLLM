//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import GeneratedOpenAIClient
import OpenAPIRuntime
@testable import Spezi
@testable import SpeziLLM
@testable import SpeziLLMOpenAI
import SwiftUI


extension LLMOpenAIMockedInferenceTests {
    /// A mock implementation of the OpenAI API `Client`
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
    
    /// Helper struct for building mocked streaming responses from the OpenAI API.
    struct ChatResponseBuilder {
        private static let responseChunkId = UUID().uuidString
        private static let responseTimestamp = Int(Date().timeIntervalSince1970)
        
        private let createMockChatResponse: (String) throws -> String = { message in
            String(decoding: try JSONEncoder().encode(
                Components.Schemas.CreateChatCompletionStreamResponse(
                    id: Self.responseChunkId,
                    choices: ([
                        .init(
                            delta: .init(content: message, role: .assistant),
                            logprobs: .none,
                            finish_reason: nil,
                            index: 0
                        )
                    ]),
                    created: Self.responseTimestamp,
                    model: "spezi-mock",
                    object: .chat_period_completion_period_chunk
                )
            ), as: UTF8.self)
        }
        
        private let createMockFunctionCallResponse: (String, String) throws -> String = { name, arguments in
            String(decoding: try JSONEncoder().encode(
                Components.Schemas.CreateChatCompletionStreamResponse(
                    id: Self.responseChunkId,
                    choices: ([
                        .init(
                            delta: .init(
                                content: .none,
                                tool_calls: [.init(index: 0, id: UUID().uuidString, function: .init(name: name, arguments: arguments))]
                            ),
                            logprobs: .none,
                            finish_reason: nil,
                            index: 0
                        )
                    ]),
                    created: Self.responseTimestamp,
                    model: "spezi-mock",
                    object: .chat_period_completion_period_chunk
                )
            ), as: UTF8.self)
        }
        
        private var data: [String] = []
        
        /// Appends a standard assistant text message to the response.
        /// - Parameter text: The message content to append.
        mutating func append(text: String) throws {
            try data.append("data: \(createMockChatResponse(text))\n\n")
        }
        
        /// Appends a tool function call message to the response.
        /// - Parameters:
        ///   - functionName: The name of the function being "called".
        ///   - arguments: The stringified arguments passed to the function.
        mutating func append(functionName: String, arguments: String) throws {
            try data.append("data: \(createMockFunctionCallResponse(functionName, arguments))\n\n")
        }
        
        /// Appends the `[DONE]` marker to signify the end of the stream.
        mutating func done() {
            data.append("data: [DONE]\n\n")
        }

        /// Converts the built response data into an `Operations.createChatCompletion.Output` object
        /// suitable for use as a mock API response.
        /// - Returns: An OpenAI API chat completion response.
        func toChatOutput() -> Operations.createChatCompletion.Output {
            let stream = AsyncStream<String> { continuation in
                for chunk in data {
                    continuation.yield(chunk)
                }
                continuation.finish()
            }
            
            let body = HTTPBody(stream, length: .unknown)

            return .ok(.init(body: .text_event_hyphen_stream(body)))
        }
    }
}
