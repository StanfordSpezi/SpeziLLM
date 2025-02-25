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
    struct ParametersOptional: Encodable {
        static let shared = Self()
        
        let intParameter = 123
        let doubleParameter: Double = 12.34
        let boolParameter = true
        let stringParameter = "1234"
        let intArrayParameter = [1, 2, 3]
        let doubleArrayParameter = [12.34, 56.78]
        let boolArrayParameter = [true, false]
        let stringArrayParameter = ["1234", "5678"]
    }
    
    struct LLMFunctionTestOptional: LLMFunction {
        static let name: String = "test_optional_function"
        static let description: String = "This is a test optional LLM function."
        
        let someInitArg: String
        
        // swiftlint:disable attributes discouraged_optional_boolean discouraged_optional_collection
        
        @Parameter(description: "Optional Int Parameter", multipleOf: 3)
        var intParameter: Int?
        @Parameter(description: "Optional Double Parameter", minimum: 12, maximum: 34)
        var doubleParameter: Double?
        @Parameter(description: "Optional Bool Parameter", const: "false")
        var boolParameter: Bool?
        @Parameter(description: "Optional String Parameter", format: .datetime, pattern: "/d/d/d/d", enum: ["1234", "5678"])
        var stringParameter: String?
        @Parameter(description: "Optional Int Array Parameter", minItems: 1, maxItems: 9, uniqueItems: true)
        var intArrayParameter: [Int]?
        @Parameter(description: "Optional Double Array Parameter", minimum: 12.3, maximum: 45.6)
        var doubleArrayParameter: [Double]?
        @Parameter(description: "Optional Bool Array Parameter", const: "true")
        var boolArrayParameter: [Bool]?
        @Parameter(description: "Optional String Array Parameter", pattern: "/d/d/d/d", enum: ["1234", "5678"])
        var stringArrayParameter: [String]?
        @Parameter(description: "Optional String Array Nil Parameter")
        var arrayNilParameter: [String]?
        
        // swiftlint:enable attributes discouraged_optional_boolean discouraged_optional_collection
        
        
        init(someInitArg: String) {
            self.someInitArg = someInitArg
        }
        
        
        func execute() async throws -> String? {
            #expect(intParameter == ParametersOptional.shared.intParameter)
            #expect(doubleParameter == ParametersOptional.shared.doubleParameter)
            #expect(boolParameter == ParametersOptional.shared.boolParameter)
            #expect(stringParameter == ParametersOptional.shared.stringParameter)
            #expect(intArrayParameter == ParametersOptional.shared.intArrayParameter)
            #expect(doubleArrayParameter == ParametersOptional.shared.doubleArrayParameter)
            #expect(boolArrayParameter == ParametersOptional.shared.boolArrayParameter)
            #expect(stringArrayParameter == ParametersOptional.shared.stringArrayParameter)
            #expect(arrayNilParameter == nil)
            
            return someInitArg
        }
    }
    
    
    @Test("Test Optional Parameters")
    func testLLMFunctionOptionalParameters() async throws { // swiftlint:disable:this function_body_length
        let llm = LLMOpenAISchema(
            parameters: .init(modelType: "gpt-4o")
        ) {
            LLMFunctionTestOptional(someInitArg: "testArg")
        }
        
        #expect(llm.functions.count == 1)
        let llmFunctionPair = try #require(llm.functions.first)
        
        // Validate parameter metadata
        #expect(llmFunctionPair.key == LLMFunctionTestOptional.name)
        let llmFunction = llmFunctionPair.value
        #expect(try #require(llmFunction.parameterValueCollectors["intParameter"]).isOptional)
        #expect(try #require(llmFunction.parameterValueCollectors["doubleParameter"]).isOptional)
        #expect(try #require(llmFunction.parameterValueCollectors["boolParameter"]).isOptional)
        #expect(try #require(llmFunction.parameterValueCollectors["stringParameter"]).isOptional)
        #expect(try #require(llmFunction.parameterValueCollectors["intArrayParameter"]).isOptional)
        #expect(try #require(llmFunction.parameterValueCollectors["doubleArrayParameter"]).isOptional)
        #expect(try #require(llmFunction.parameterValueCollectors["boolArrayParameter"]).isOptional)
        #expect(try #require(llmFunction.parameterValueCollectors["stringArrayParameter"]).isOptional)
        #expect(try #require(llmFunction.parameterValueCollectors["arrayNilParameter"]).isOptional)
        
        // Validate parameter schema
        let schemaOptionalInt = try #require(llmFunction.schemaValueCollectors["intParameter"])
        var schema = schemaOptionalInt.schema.value
        #expect(schema["type"] as? String == "integer")
        #expect(schema["description"] as? String == "Optional Int Parameter")
        #expect(schema["multipleOf"] as? Int == 3)
        
        let schemaOptionalDouble = try #require(llmFunction.schemaValueCollectors["doubleParameter"])
        schema = schemaOptionalDouble.schema.value
        #expect(schema["type"] as? String == "number")
        #expect(schema["description"] as? String == "Optional Double Parameter")
        #expect(schema["minimum"] as? Double == 12)
        #expect(schema["maximum"] as? Double == 34)
        
        let schemaOptionalBool = try #require(llmFunction.schemaValueCollectors["boolParameter"])
        schema = schemaOptionalBool.schema.value
        #expect(schema["type"] as? String == "boolean")
        #expect(schema["description"] as? String == "Optional Bool Parameter")
        #expect(schema["const"] as? String == "false")
        
        let schemaOptionalString = try #require(llmFunction.schemaValueCollectors["stringParameter"])
        schema = schemaOptionalString.schema.value
        #expect(schema["type"] as? String == "string")
        #expect(schema["description"] as? String == "Optional String Parameter")
        #expect(schema["format"] as? String == "date-time")
        #expect(schema["pattern"] as? String == "/d/d/d/d")
        #expect(schema["enum"] as? [String] == ["1234", "5678"])
        
        let schemaArrayInt = try #require(llmFunction.schemaValueCollectors["intArrayParameter"])
        schema = schemaArrayInt.schema.value
        var items = schema["items"] as? [String: Any]
        #expect(schema["type"] as? String == "array")
        #expect(schema["description"] as? String == "Optional Int Array Parameter")
        #expect(schema["minItems"] as? Int == 1)
        #expect(schema["maxItems"] as? Int == 9)
        #expect(schema["uniqueItems"] as? Bool ?? false)
        #expect(items?["type"] as? String == "integer")
        
        let schemaArrayDouble = try #require(llmFunction.schemaValueCollectors["doubleArrayParameter"])
        schema = schemaArrayDouble.schema.value
        items = schema["items"] as? [String: Any]
        #expect(schema["type"] as? String == "array")
        #expect(schema["description"] as? String == "Optional Double Array Parameter")
        #expect(items?["type"] as? String == "number")
        #expect(items?["minimum"] as? Double == 12.3)
        #expect(items?["maximum"] as? Double == 45.6)
        
        let schemaArrayBool = try #require(llmFunction.schemaValueCollectors["boolArrayParameter"])
        schema = schemaArrayBool.schema.value
        items = schema["items"] as? [String: Any]
        #expect(schema["type"] as? String == "array")
        #expect(schema["description"] as? String == "Optional Bool Array Parameter")
        #expect(items?["type"] as? String == "boolean")
        #expect(items?["const"] as? String == "true")
        
        let schemaArrayString = try #require(llmFunction.schemaValueCollectors["stringArrayParameter"])
        schema = schemaArrayString.schema.value
        items = schema["items"] as? [String: Any]
        #expect(schema["type"] as? String == "array")
        #expect(schema["description"] as? String == "Optional String Array Parameter")
        #expect(items?["type"] as? String == "string")
        #expect(items?["pattern"] as? String == "/d/d/d/d")
        #expect(items?["enum"] as? [String] == ["1234", "5678"])
        
        // Validate parameter injection
        let parameterData = try #require(
            try JSONEncoder().encode(ParametersOptional.shared)
        )
        
        try llmFunction.injectParameters(from: parameterData)
        let llmFunctionResponse = try await llmFunction.execute()
        #expect(llmFunctionResponse == "testArg")
    }
}
