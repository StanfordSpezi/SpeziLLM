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
    struct CustomType: LLMFunctionParameterArrayElement, Encodable, Equatable {
        static let itemSchema: LLMFunctionParameterItemSchema = {
            do {
                return try .init(unvalidatedValue: [
                    "type": "object",
                    "properties": [
                        "propertyA": [
                            "type": "string",
                            "description": "First parameter"
                        ],
                        "propertyB": [
                            "type": "integer",
                            "description": "Second parameter"
                        ]
                    ]
                ])
            } catch {
                print("unable to initialse schema in LLMOpenAIParameterCustomTypesTets")
                return .init()
            }
        }()

        var propertyA: String
        var propertyB: Int
    }

    struct ParametersCustom: Encodable {
        static let shared = Self()

        let customArrayParameter = [
            CustomType(propertyA: "testA", propertyB: 123),
            CustomType(propertyA: "testB", propertyB: 456)
        ]
        
        let customOptionalArrayParameter: [CustomType] = []
    }
    
    struct LLMFunctionTestCustom: LLMFunction {
        static let name: String = "test_custom_type_function"
        static let description: String = "This is a test custom type LLM function."
        
        let someInitArg: String

        @Parameter(description: "Custom Array Parameter", minItems: 1, maxItems: 5, uniqueItems: false)
        var customArrayParameter: [CustomType]
        @Parameter(description: "Custom Optional Array Parameter")
        var customOptionalArrayParameter: [CustomType]?     // swiftlint:disable:this discouraged_optional_collection
                
        
        init(someInitArg: String) {
            self.someInitArg = someInitArg
        }
        
        
        func execute() async throws -> String? {
            #expect(customArrayParameter == ParametersCustom.shared.customArrayParameter)
            #expect(customOptionalArrayParameter == ParametersCustom.shared.customOptionalArrayParameter)
            
            return someInitArg
        }
    }
    
    
    @Test("Test Custom Type Parameters")
    func testLLMFunctionCustomParameters() async throws {
        let llm = LLMOpenAISchema(
            parameters: .init(modelType: "gpt-4o")
        ) {
            LLMFunctionTestCustom(someInitArg: "testArg")
        }

        #expect(llm.functions.count == 1)
        let llmFunctionPair = try #require(llm.functions.first)
        
        // Validate parameter metadata
        #expect(llmFunctionPair.key == LLMFunctionTestCustom.name)
        let llmFunction = llmFunctionPair.value
        #expect(try #require(llmFunction.parameterValueCollectors["customArrayParameter"]).isOptional == false)
        #expect(try #require(llmFunction.parameterValueCollectors["customOptionalArrayParameter"]).isOptional)
        
        // Validate parameter schema
        let schemaCustomArray = try #require(llmFunction.schemaValueCollectors["customArrayParameter"])
        var schema = schemaCustomArray.schema.value
        var items = schemaCustomArray.schema.value["items"] as? [String: Any]
        var properties = items?["properties"] as? [String: Any]
        
        #expect(schema["type"] as? String == "array")
        #expect(schema["description"] as? String == "Custom Array Parameter")
        #expect(schema["minItems"] as? Int == 1)
        #expect(schema["maxItems"] as? Int == 5)
        #expect(!(schema["uniqueItems"] as? Bool ?? true))
        #expect(items?["type"] as? String == "object")
        #expect((properties?["propertyA"] as? [String: Any])?["type"] as? String == "string")
        #expect((properties?["propertyA"] as? [String: Any])?["description"] as? String == "First parameter")
        #expect((properties?["propertyB"] as? [String: Any])?["type"] as? String == "integer")
        #expect((properties?["propertyB"] as? [String: Any])?["description"] as? String == "Second parameter")
        
        let schemaCustomOptionalArray = try #require(llmFunction.schemaValueCollectors["customOptionalArrayParameter"])
        schema = schemaCustomOptionalArray.schema.value
        items = schemaCustomOptionalArray.schema.value["items"] as? [String: Any]
        properties = items?["properties"] as? [String: Any]
        
        #expect(schema["type"] as? String == "array")
        #expect(schema["description"] as? String == "Custom Optional Array Parameter")
        #expect(items?["type"] as? String == "object")
        #expect((properties?["propertyA"] as? [String: Any])?["type"] as? String == "string")
        #expect((properties?["propertyA"] as? [String: Any])?["description"] as? String == "First parameter")
        #expect((properties?["propertyB"] as? [String: Any])?["type"] as? String == "integer")
        #expect((properties?["propertyB"] as? [String: Any])?["description"] as? String == "Second parameter")
        
        // Validate parameter injection
        let parameterData = try #require(
            try JSONEncoder().encode(ParametersCustom.shared)
        )
        
        try llmFunction.injectParameters(from: parameterData)
        let llmFunctionResponse = try await llmFunction.execute()
        #expect(llmFunctionResponse == "testArg")
    }
}
