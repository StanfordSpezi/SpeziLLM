//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
@testable import SpeziLLMOpenAI
import Testing


@Suite
struct FunctionCallingTests {
    @Test
    func parallelExecution() async throws {
        struct TestFunction: LLMFunction {
            static let name = "identity"
            static let description = "Identity Function"
            
            @Parameter(description: "Input") var input: String
            
            func execute() async throws -> String? {
                try await Task.sleep(for: .seconds(2))
                return input
            }
        }
        
        struct Input: Encodable {
            let input: String
        }
        
        let llm = LLMOpenAISchema(
            parameters: .init(modelType: .gpt4o)
        ) {
            TestFunction()
        }
        
        #expect(llm.functions.count == 1)
        let llmFunctionPair = try #require(llm.functions.first)
        
        // Validate parameter metadata
        #expect(llmFunctionPair.key == TestFunction.name)
        let llmFunction = llmFunctionPair.value
        #expect(try #require(llmFunction.parameters["input"]).isOptional == false)
        
        // Validate parameter schema
        let schemaInputParam = try #require(llmFunction.schemaValueCollectors["input"])
        #expect(schemaInputParam.schema.value["type"] as? String == "string")
        #expect(schemaInputParam.schema.value["description"] as? String == "Input")
        #expect(schemaInputParam.schema.value["multipleOf"] as? Int == nil)
        
        try await withThrowingDiscardingTaskGroup { taskGroup in
            let cities = ["Munich", "London", "New York", "Adelaide"]
            for city in cities {
                taskGroup.addTask {
                    let parameterData = try JSONEncoder().encode(Input(input: city))
                    let arguments = try LLMFunctionCallArguments(from: parameterData, for: llmFunction)
                    let response = try await llmFunction._execute(arguments)
                    #expect(response == city)
                }
            }
        }
    }
}
