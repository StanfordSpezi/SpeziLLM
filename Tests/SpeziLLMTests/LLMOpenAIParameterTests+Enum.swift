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


struct LLMOpenAIParameterEnumTests {
    enum CustomEnumType: String, LLMFunctionParameterEnum, Encodable {
        case optionA
        case optionB
    }
    
    struct Parameters: Encodable {
        static let shared = Self()
        
        let enumParameter = CustomEnumType.optionB
        let optionalEnumParameter = CustomEnumType.optionA
        let arrayEnumParameter = [CustomEnumType.optionA, CustomEnumType.optionB]
        let optionalArrayEnumParameter = [CustomEnumType.optionB, CustomEnumType.optionA]
    }
    
    struct LLMFunctionTest: LLMFunction {
        static let name: String = "test_enum_function"
        static let description: String = "This is a test enum LLM function."
        
        let someInitArg: String
        
        // swiftlint:disable attributes
        
        @Parameter(description: "Enum Parameter", const: "optionA")
        var enumParameter: CustomEnumType
        @Parameter(description: "Optional Enum Parameter")
        var optionalEnumParameter: CustomEnumType?
        @Parameter(description: "Array Enum Parameter", minItems: 1, maxItems: 5, uniqueItems: false)
        var arrayEnumParameter: [CustomEnumType]
        @Parameter(description: "Optional Array Enum Parameter")
        var optionalArrayEnumParameter: [CustomEnumType]?   // swiftlint:disable:this discouraged_optional_collection
        
        // swiftlint:enable attributes
        
        
        init(someInitArg: String) {
            self.someInitArg = someInitArg
        }
        
        
        func execute() async throws -> String? {
            #expect(enumParameter == Parameters.shared.enumParameter)
            #expect(optionalEnumParameter == Parameters.shared.optionalEnumParameter)
            #expect(arrayEnumParameter == Parameters.shared.arrayEnumParameter)
            #expect(optionalArrayEnumParameter == Parameters.shared.optionalArrayEnumParameter)
            
            return someInitArg
        }
    }
    
    let llm = LLMOpenAISchema(
        parameters: .init(modelType: "gpt-4o")
    ) {
        LLMFunctionTest(someInitArg: "testArg")
    }
    
    func testLLMFunctionPrimitiveParameters() async throws {
        #expect(llm.functions.count == 1)
        let llmFunctionPair = try #require(llm.functions.first)
        
        // Validate parameter metadata
        #expect(llmFunctionPair.key == LLMFunctionTest.name)
        let llmFunction = llmFunctionPair.value
        #expect(!(try #require(llmFunction.parameterValueCollectors["enumParameter"])).isOptional)
        #expect(try #require(llmFunction.parameterValueCollectors["optionalEnumParameter"]).isOptional)
        #expect(!(try #require(llmFunction.parameterValueCollectors["arrayEnumParameter"])).isOptional)
        #expect(try #require(llmFunction.parameterValueCollectors["optionalArrayEnumParameter"]).isOptional)
        
        // Validate parameter schema
        let schemaEnum = try #require(llmFunction.schemaValueCollectors["enumParameter"])
        var schema = schemaEnum.schema.value
        #expect(schema["type"] as? String == "string")
        #expect(schema["description"] as? String == "Enum Parameter")
        #expect(schema["const"] as? String == "optionA")
        #expect(schema["enum"] as? [String] == CustomEnumType.allCases.map { $0.rawValue })
        
        let schemaOptionalEnum = try #require(llmFunction.schemaValueCollectors["optionalEnumParameter"])
        schema = schemaOptionalEnum.schema.value
        #expect(schema["type"] as? String == "string")
        #expect(schema["description"] as? String == "Optional Enum Parameter")
        #expect(schema["enum"] as? [String] == CustomEnumType.allCases.map { $0.rawValue })
        
        let schemaArrayEnum = try #require(llmFunction.schemaValueCollectors["arrayEnumParameter"])
        schema = schemaArrayEnum.schema.value
        var items = schema["items"] as? [String: Any]
        #expect(schema["type"] as? String == "array")
        #expect(schema["description"] as? String == "Array Enum Parameter")
        #expect(schema["minItems"] as? Int == 1)
        #expect(schema["maxItems"] as? Int == 5)
        #expect(!(schema["uniqueItems"] as? Bool ?? true))
        #expect(items?["type"] as? String == "string")
        #expect(items?["enum"] as? [String] == CustomEnumType.allCases.map { $0.rawValue })
        
        let schemaOptionalArrayEnum = try #require(llmFunction.schemaValueCollectors["optionalArrayEnumParameter"])
        schema = schemaOptionalArrayEnum.schema.value
        items = schema["items"] as? [String: Any]
        #expect(schema["type"] as? String == "array")
        #expect(schema["description"] as? String == "Optional Array Enum Parameter")
        #expect(items?["type"] as? String == "string")
        #expect(items?["enum"] as? [String] == CustomEnumType.allCases.map { $0.rawValue })
        
        // Validate parameter injection
        let parameterData = try #require(
            try JSONEncoder().encode(Parameters.shared)
        )
        
        try llmFunction.injectParameters(from: parameterData)
        let llmFunctionResponse = try await llmFunction.execute()
        #expect(llmFunctionResponse == "testArg")
    }
}
