//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
@testable import SpeziLLMOpenAI
import Testing


struct LLMOpenAIInvalidParametersTests {
    struct Parameters: Encodable {
        static let shared = Self()
        
        let intParameter = 12
    }
    
    struct LLMFunctionTest: LLMFunction {
        static let name: String = "test_invalid_parameters_function"
        static let description: String = "This is a test invalid parameters LLM function."
        
        let someInitArg: String
        
        // swiftlint:disable attributes
        
        @Parameter(description: "Random Parameter", pattern: "/d/d/d/d")
        var randomParameter: String
        
        // swiftlint:enable attributes
        
        
        init(someInitArg: String) {
            self.someInitArg = someInitArg
        }
        
        
        func execute() async throws -> String? {
            Issue.record("Execution of function should have never happened as parameters mismatch!")
            
            return someInitArg
        }
    }
    
    let llm = LLMOpenAISchema(
        parameters: .init(modelType: "gpt-4o")
    ) {
        LLMFunctionTest(someInitArg: "testArg")
    }
    
    @Test()
    func testLLMFunctionPrimitiveParameters() async throws {
        #expect(llm.functions.count == 1)
        let llmFunctionPair = try #require(llm.functions.first)
        
        // Validate parameter metadata
        #expect(llmFunctionPair.key == LLMFunctionTest.name)
        let llmFunction = llmFunctionPair.value
        #expect(!(try #require(llmFunction.parameterValueCollectors["randomParameter"])).isOptional)
        
        // Validate parameter schema
        let schemaRandomParameter = try #require(llmFunction.schemaValueCollectors["randomParameter"])
        let schema = schemaRandomParameter.schema.value
        #expect(schema["type"] as? String == "string")
        #expect(schema["description"] as? String == "Random Parameter")
        #expect(schema["pattern"] as? String == "/d/d/d/d")
        
        // Validate parameter injection
        let parameterData = try #require(
            try JSONEncoder().encode(Parameters.shared)
        )
        
        #expect(
            throws: (any Error).self,
            "Mismatch between the defined values of the LLM Function and the requested values by the LLM"
        ) {
            try llmFunction.injectParameters(from: parameterData)
        }
    }
}
