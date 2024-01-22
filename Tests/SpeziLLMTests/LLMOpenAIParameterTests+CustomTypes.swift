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
        static var itemSchema: SpeziLLMOpenAI.LLMFunctionParameterItemSchema = .init(
            type: .object,
            properties: [
                "propertyA": .init(type: .string, description: "First parameter"),
                "propertyB": .init(type: .integer, description: "Second parameter")
            ]
        )
        
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
    
    let llm = LLMOpenAI(
        parameters: .init(modelType: .gpt4_1106_preview)
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
        XCTAssertEqual(schemaCustomArray.schema.type, .array)
        XCTAssertEqual(schemaCustomArray.schema.description, "Custom Array Parameter")
        XCTAssertEqual(schemaCustomArray.schema.minItems, 1)
        XCTAssertEqual(schemaCustomArray.schema.maxItems, 5)
        XCTAssertFalse(schemaCustomArray.schema.uniqueItems ?? true)
        XCTAssertEqual(schemaCustomArray.schema.items?.type, .object)
        XCTAssertEqual(schemaCustomArray.schema.items?.properties?["propertyA"]?.type, .string)
        XCTAssertEqual(schemaCustomArray.schema.items?.properties?["propertyA"]?.description, "First parameter")
        XCTAssertEqual(schemaCustomArray.schema.items?.properties?["propertyB"]?.type, .integer)
        XCTAssertEqual(schemaCustomArray.schema.items?.properties?["propertyB"]?.description, "Second parameter")
        
        let schemaCustomOptionalArray = try XCTUnwrap(llmFunction.schemaValueCollectors["customOptionalArrayParameter"])
        XCTAssertEqual(schemaCustomOptionalArray.schema.type, .array)
        XCTAssertEqual(schemaCustomOptionalArray.schema.description, "Custom Optional Array Parameter")
        XCTAssertEqual(schemaCustomOptionalArray.schema.items?.type, .object)
        XCTAssertEqual(schemaCustomOptionalArray.schema.items?.properties?["propertyA"]?.type, .string)
        XCTAssertEqual(schemaCustomOptionalArray.schema.items?.properties?["propertyA"]?.description, "First parameter")
        XCTAssertEqual(schemaCustomOptionalArray.schema.items?.properties?["propertyB"]?.type, .integer)
        XCTAssertEqual(schemaCustomOptionalArray.schema.items?.properties?["propertyB"]?.description, "Second parameter")
        
        // Validate parameter injection
        let parameterData = try XCTUnwrap(
            JSONEncoder().encode(Parameters.shared)
        )
        
        try llmFunction.injectParameters(from: parameterData)
        let llmFunctionResponse = try await llmFunction.execute()
        XCTAssertEqual(llmFunctionResponse, "testArg")
    }
}
