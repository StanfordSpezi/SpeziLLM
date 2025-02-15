//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

@testable import SpeziLLMOpenAI
import XCTest


final class LLMOpenAIParameterCustomTypesTests: XCTestCase {
    struct CustomType: LLMFunctionParameterArrayElement, Encodable, Equatable {
        static var itemSchema: LLMFunctionParameterItemSchema = {
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

    struct Parameters: Encodable {
        static let shared = Self()

        let customArrayParameter = [
            CustomType(propertyA: "testA", propertyB: 123),
            CustomType(propertyA: "testB", propertyB: 456)
        ]
        
        let customOptionalArrayParameter: [CustomType] = []
    }
    
    struct LLMFunctionTest: LLMFunction {
        static var name: String = "test_custom_type_function"
        static var description: String = "This is a test custom type LLM function."
        
        let someInitArg: String
        
        // swiftlint:disable attributes
        
        @Parameter(description: "Custom Array Parameter", minItems: 1, maxItems: 5, uniqueItems: false)
        var customArrayParameter: [CustomType]
        @Parameter(description: "Custom Optional Array Parameter")
        var customOptionalArrayParameter: [CustomType]?     // swiftlint:disable:this discouraged_optional_collection
        
        // swiftlint:enable attributes
        
        
        init(someInitArg: String) {
            self.someInitArg = someInitArg
        }
        
        
        func execute() async throws -> String? {
            XCTAssertEqual(customArrayParameter, Parameters.shared.customArrayParameter)
            XCTAssertEqual(customOptionalArrayParameter, Parameters.shared.customOptionalArrayParameter)
            
            return someInitArg
        }
    }
    
    let llm = LLMOpenAISchema(
        parameters: .init(modelType: .init(value1: "GPT 4 Turbo", value2: .gpt_hyphen_4_hyphen_turbo))  // todo: upgrade gpt-4o
    ) {
        LLMFunctionTest(someInitArg: "testArg")
    }
    
    func testLLMFunctionPrimitiveParameters() async throws {
        XCTAssertEqual(llm.functions.count, 1)
        let llmFunctionPair = try XCTUnwrap(llm.functions.first)
        
        // Validate parameter metadata
        XCTAssertEqual(llmFunctionPair.key, LLMFunctionTest.name)
        let llmFunction = llmFunctionPair.value
        XCTAssert(!(try XCTUnwrap(llmFunction.parameterValueCollectors["customArrayParameter"])).isOptional)
        XCTAssert(try XCTUnwrap(llmFunction.parameterValueCollectors["customOptionalArrayParameter"]).isOptional)
        
        // Validate parameter schema
        let schemaCustomArray = try XCTUnwrap(llmFunction.schemaValueCollectors["customArrayParameter"])
        var schema = schemaCustomArray.schema.value
        var items = schemaCustomArray.schema.value["items"] as? [String: Any]
        var properties = items?["properties"] as? [String: Any]
        
        XCTAssertEqual(schema["type"] as? String, "array")
        XCTAssertEqual(schema["description"] as? String, "Custom Array Parameter")
        XCTAssertEqual(schema["minItems"] as? Int, 1)
        XCTAssertEqual(schema["maxItems"] as? Int, 5)
        XCTAssertFalse(schema["uniqueItems"] as? Bool ?? true)
        XCTAssertEqual(items?["type"] as? String, "object")
        XCTAssertEqual((properties?["propertyA"] as? [String: Any])?["type"] as? String, "string")
        XCTAssertEqual((properties?["propertyA"] as? [String: Any])?["description"] as? String, "First parameter")
        XCTAssertEqual((properties?["propertyB"] as? [String: Any])?["type"] as? String, "integer")
        XCTAssertEqual((properties?["propertyB"] as? [String: Any])?["description"] as? String, "Second parameter")
        
        let schemaCustomOptionalArray = try XCTUnwrap(llmFunction.schemaValueCollectors["customOptionalArrayParameter"])
        schema = schemaCustomOptionalArray.schema.value
        items = schemaCustomOptionalArray.schema.value["items"] as? [String: Any]
        properties = items?["properties"] as? [String: Any]
        
        XCTAssertEqual(schema["type"] as? String, "array")
        XCTAssertEqual(schema["description"] as? String, "Custom Optional Array Parameter")
        XCTAssertEqual(items?["type"] as? String, "object")
        XCTAssertEqual((properties?["propertyA"] as? [String: Any])?["type"] as? String, "string")
        XCTAssertEqual((properties?["propertyA"] as? [String: Any])?["description"] as? String, "First parameter")
        XCTAssertEqual((properties?["propertyB"] as? [String: Any])?["type"] as? String, "integer")
        XCTAssertEqual((properties?["propertyB"] as? [String: Any])?["description"] as? String, "Second parameter")
        
        // Validate parameter injection
        let parameterData = try XCTUnwrap(
            JSONEncoder().encode(Parameters.shared)
        )
        
        try llmFunction.injectParameters(from: parameterData)
        let llmFunctionResponse = try await llmFunction.execute()
        XCTAssertEqual(llmFunctionResponse, "testArg")
    }
}
