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


extension LLMOpenAIMockedInferenceTests {
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
        static let responseChunkId = UUID().uuidString
        static let responseTimestamp = Int(Date().timeIntervalSince1970)
        
        let createMockChatResponse: (String) throws -> String = { message in
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

        let createMockFunctionCallResponse: (String, String) throws -> String = { name, arguments in
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
        
        private(set) var data: [String] = []
        
        mutating func append(text: String) throws {
            try data.append("data: \(createMockChatResponse(text))\n\n")
        }

        mutating func append(functionName: String, arguments: String) throws {
            try data.append("data: \(createMockFunctionCallResponse(functionName, arguments))\n\n")
        }

        mutating func done() {
            data.append("data: [DONE]\n\n")
        }
        
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
