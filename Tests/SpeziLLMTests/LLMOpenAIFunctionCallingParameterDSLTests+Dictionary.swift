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
    struct ParametersDictionary: Encodable {
        static let shared = Self()
        
        let intDictionaryParameter = ["one": 1, "two": 2]
        let doubleDictionaryParameter = ["three": 3.1, "four": 4.6]
        let boolDictionaryParameter = ["isTrue": true, "isFalse": false]
        let stringDictionaryParameter = ["first": "test1", "second": "test2"]
    }
    
    struct LLMFunctionTestDictionary: LLMFunction {
        static let name: String = "test_dictionary_function"
        static let description: String = "This is a test dictionary LLM function."
        
        let someInitArg: String
        
        // swiftlint:disable attributes
        
        @Parameter(description: "Int Dictionary Parameter")
        var intDictionaryParameter: [String: Int]
        @Parameter(description: "Double Dictionary Parameter")
        var doubleDictionaryParameter: [String: Double]
        @Parameter(description: "Bool Dictionary Parameter", const: "true")
        var boolDictionaryParameter: [String: Bool]
        @Parameter(description: "String Dictionary Parameter")
        var stringDictionaryParameter: [String: String]
        
        // swiftlint:enable attributes
        
        
        init(someInitArg: String) {
            self.someInitArg = someInitArg
        }
        
        
        func execute() async throws -> String? {
            #expect(intDictionaryParameter == ParametersDictionary.shared.intDictionaryParameter)
            #expect(doubleDictionaryParameter == ParametersDictionary.shared.doubleDictionaryParameter)
            #expect(boolDictionaryParameter == ParametersDictionary.shared.boolDictionaryParameter)
            #expect(stringDictionaryParameter == ParametersDictionary.shared.stringDictionaryParameter)
            
            return someInitArg
        }
    }
    
    
    @Test("Test Dictionary Parameters")
    func testLLMFunctionDictionaryParameters() async throws { // swiftlint:disable:this function_body_length
        let llm = LLMOpenAISchema(
            parameters: .init(modelType: "gpt-4o")
        ) {
            LLMFunctionTestDictionary(someInitArg: "testArg")
        }

        #expect(llm.functions.count == 1)
        let llmFunctionPair = try #require(llm.functions.first)
        
        // Validate parameter metadata
        #expect(llmFunctionPair.key == LLMFunctionTestDictionary.name)
        let llmFunction = llmFunctionPair.value
        #expect(try #require(llmFunction.parameterValueCollectors["intDictionaryParameter"]).isOptional == false)
        #expect(try #require(llmFunction.parameterValueCollectors["doubleDictionaryParameter"]).isOptional == false)
        #expect(try #require(llmFunction.parameterValueCollectors["boolDictionaryParameter"]).isOptional == false)
        #expect(try #require(llmFunction.parameterValueCollectors["stringDictionaryParameter"]).isOptional == false)
        
        // Validate parameter schema
        let schemaDictionaryInt = try #require(llmFunction.schemaValueCollectors["intDictionaryParameter"])
        var schema = schemaDictionaryInt.schema.value
        var additionalProperties = schema["additionalProperties"] as? [String: Any]
        #expect(schema["type"] as? String == "object")
        #expect(schema["description"] as? String == "Int Dictionary Parameter")
        #expect(additionalProperties?["type"] as? String == "integer")
        
        let schemaDictionaryDouble = try #require(llmFunction.schemaValueCollectors["doubleDictionaryParameter"])
        schema = schemaDictionaryDouble.schema.value
        additionalProperties = schema["additionalProperties"] as? [String: Any]
        #expect(schema["type"] as? String == "object")
        #expect(schema["description"] as? String == "Double Dictionary Parameter")
        #expect(additionalProperties?["type"] as? String == "number")
        
        let schemaDictionaryBool = try #require(llmFunction.schemaValueCollectors["boolDictionaryParameter"])
        schema = schemaDictionaryBool.schema.value
        additionalProperties = schema["additionalProperties"] as? [String: Any]
        #expect(schema["type"] as? String == "object")
        #expect(schema["description"] as? String == "Bool Dictionary Parameter")
        #expect(schema["const"] as? String == "true")
        #expect(additionalProperties?["type"] as? String == "boolean")
        
        let schemaDictionaryString = try #require(llmFunction.schemaValueCollectors["stringDictionaryParameter"])
        schema = schemaDictionaryString.schema.value
        additionalProperties = schema["additionalProperties"] as? [String: Any]
        #expect(schema["type"] as? String == "object")
        #expect(schema["description"] as? String == "String Dictionary Parameter")
        #expect(additionalProperties?["type"] as? String == "string")
        
        // Validate parameter injection
        let parameterData = try JSONEncoder().encode(ParametersDictionary.shared)
        
        try llmFunction.injectParameters(from: parameterData)
        let llmFunctionResponse = try await llmFunction.execute()
        #expect(llmFunctionResponse == "testArg")
    }
}
