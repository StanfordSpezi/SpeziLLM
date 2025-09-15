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


extension LLMOpenAIFunctionCallingParameterDSLTests {
    struct ParametersArray: Encodable {
        static let shared = Self()
        
        let intArrayParameter = [1, 2]
        let doubleArrayParameter = [3.1, 4.6]
        let boolArrayParameter = [true, false]
        let stringArrayParameter = ["test1", "test2"]
    }
    
    struct LLMFunctionTestArray: LLMFunction {
        static let name: String = "test_array_function"
        static let description: String = "This is a test array LLM function."
        
        let someInitArg: String

        @Parameter(description: "Int Array Parameter", minItems: 1, maxItems: 9, uniqueItems: true)
        var intArrayParameter: [Int]
        @Parameter(description: "Double Array Parameter", minimum: 12.3, maximum: 45.6)
        var doubleArrayParameter: [Double]
        @Parameter(description: "Bool Array Parameter", const: "true")
        var boolArrayParameter: [Bool]
        @Parameter(description: "String Array Parameter", pattern: "/d/d/d/d", enum: ["1234", "5678"])
        var stringArrayParameter: [String]

        
        init(someInitArg: String) {
            self.someInitArg = someInitArg
        }
        
        
        func execute() async throws -> String? {
            #expect(intArrayParameter == ParametersArray.shared.intArrayParameter)
            #expect(doubleArrayParameter == ParametersArray.shared.doubleArrayParameter)
            #expect(boolArrayParameter == ParametersArray.shared.boolArrayParameter)
            #expect(stringArrayParameter == ParametersArray.shared.stringArrayParameter)
            
            return someInitArg
        }
    }
    
    
    @Test("Test Array Parameters")
    func testLLMFunctionArrayParameters() async throws {
        let llm = LLMOpenAISchema(
            parameters: .init(modelType: "gpt-4o")
        ) {
            LLMFunctionTestArray(someInitArg: "testArg")
        }

        #expect(llm.functions.count == 1)
        let llmFunctionPair = try #require(llm.functions.first)
        
        // Validate parameter metadata
        #expect(llmFunctionPair.key == LLMFunctionTestArray.name)
        let llmFunction = llmFunctionPair.value
        #expect(try #require(llmFunction.parameterValueCollectors["intArrayParameter"]).isOptional == false)
        #expect(try #require(llmFunction.parameterValueCollectors["doubleArrayParameter"]).isOptional == false)
        #expect(try #require(llmFunction.parameterValueCollectors["boolArrayParameter"]).isOptional == false)
        #expect(try #require(llmFunction.parameterValueCollectors["stringArrayParameter"]).isOptional == false)
        
        // Validate parameter schema
        let schemaArrayInt = try #require(llmFunction.schemaValueCollectors["intArrayParameter"])
        var schema = schemaArrayInt.schema.value
        var items = schema["items"] as? [String: Any]
        #expect(schema["type"] as? String == "array")
        #expect(schema["description"] as? String == "Int Array Parameter")
        #expect(schema["minItems"] as? Int == 1)
        #expect(schema["maxItems"] as? Int == 9)
        #expect(schema["uniqueItems"] as? Bool ?? false)
        #expect(items?["type"] as? String == "integer")
        
        let schemaArrayDouble = try #require(llmFunction.schemaValueCollectors["doubleArrayParameter"])
        schema = schemaArrayDouble.schema.value
        items = schema["items"] as? [String: Any]
        #expect(schema["type"] as? String == "array")
        #expect(schema["description"] as? String == "Double Array Parameter")
        #expect(items?["type"] as? String == "number")
        #expect(items?["minimum"] as? Double == 12.3)
        #expect(items?["maximum"] as? Double == 45.6)
        
        let schemaArrayBool = try #require(llmFunction.schemaValueCollectors["boolArrayParameter"])
        schema = schemaArrayBool.schema.value
        items = schema["items"] as? [String: Any]
        #expect(schema["type"] as? String == "array")
        #expect(schema["description"] as? String == "Bool Array Parameter")
        #expect(items?["type"] as? String == "boolean")
        #expect(items?["const"] as? String == "true")
        
        let schemaArrayString = try #require(llmFunction.schemaValueCollectors["stringArrayParameter"])
        schema = schemaArrayString.schema.value
        items = schema["items"] as? [String: Any]
        #expect(schema["type"] as? String == "array")
        #expect(schema["description"] as? String == "String Array Parameter")
        #expect(items?["type"] as? String == "string")
        #expect(items?["pattern"] as? String == "/d/d/d/d")
        #expect(items?["enum"] as? [String] == ["1234", "5678"])
        
        // Validate parameter injection
        let parameterData = try JSONEncoder().encode(ParametersArray.shared)
        
        try llmFunction.injectParameters(from: parameterData)
        let llmFunctionResponse = try await llmFunction.execute()
        #expect(llmFunctionResponse == "testArg")
    }
}
