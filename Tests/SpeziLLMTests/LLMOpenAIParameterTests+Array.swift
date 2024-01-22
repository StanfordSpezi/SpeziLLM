//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

@testable import SpeziLLMOpenAI
import XCTest


final class LLMOpenAIParameterArrayTests: XCTestCase {
    struct Parameters: Encodable {
        static let shared = Self()
        
        let intArrayParameter = [1, 2]
        let doubleArrayParameter = [3.1, 4.6]
        let boolArrayParameter = [true, false]
        let stringArrayParameter = ["test1", "test2"]
    }
    
    struct LLMFunctionTest: LLMFunction {
        static var name: String = "test_array_function"
        static var description: String = "This is a test array LLM function."
        
        let someInitArg: String
        
        // swiftlint:disable attributes
        
        @Parameter(description: "Int Array Parameter", minItems: 1, maxItems: 9, uniqueItems: true)
        var intArrayParameter: [Int]
        @Parameter(description: "Double Array Parameter", minimum: 12.3, maximum: 45.6)
        var doubleArrayParameter: [Double]
        @Parameter(description: "Bool Array Parameter", const: "true")
        var boolArrayParameter: [Bool]
        @Parameter(description: "String Array Parameter", pattern: "/d/d/d/d", enumValues: ["1234", "5678"])
        var stringArrayParameter: [String]
        
        // swiftlint:enable attributes
        
        
        init(someInitArg: String) {
            self.someInitArg = someInitArg
        }
        
        
        func execute() async throws -> String? {
            XCTAssertEqual(intArrayParameter, Parameters.shared.intArrayParameter)
            XCTAssertEqual(doubleArrayParameter, Parameters.shared.doubleArrayParameter)
            XCTAssertEqual(boolArrayParameter, Parameters.shared.boolArrayParameter)
            XCTAssertEqual(stringArrayParameter, Parameters.shared.stringArrayParameter)
            
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
        XCTAssert(!(try XCTUnwrap(llmFunction.parameterValueCollectors["intArrayParameter"])).isOptional)
        XCTAssert(!(try XCTUnwrap(llmFunction.parameterValueCollectors["doubleArrayParameter"])).isOptional)
        XCTAssert(!(try XCTUnwrap(llmFunction.parameterValueCollectors["boolArrayParameter"])).isOptional)
        XCTAssert(!(try XCTUnwrap(llmFunction.parameterValueCollectors["stringArrayParameter"])).isOptional)
        
        // Validate parameter schema
        let schemaArrayInt = try XCTUnwrap(llmFunction.schemaValueCollectors["intArrayParameter"])
        XCTAssertEqual(schemaArrayInt.schema.type, .array)
        XCTAssertEqual(schemaArrayInt.schema.description, "Int Array Parameter")
        XCTAssertEqual(schemaArrayInt.schema.minItems, 1)
        XCTAssertEqual(schemaArrayInt.schema.maxItems, 9)
        XCTAssertTrue(schemaArrayInt.schema.uniqueItems ?? false)
        XCTAssertEqual(schemaArrayInt.schema.items?.type, .integer)
        
        let schemaArrayDouble = try XCTUnwrap(llmFunction.schemaValueCollectors["doubleArrayParameter"])
        XCTAssertEqual(schemaArrayDouble.schema.type, .array)
        XCTAssertEqual(schemaArrayDouble.schema.description, "Double Array Parameter")
        XCTAssertEqual(schemaArrayDouble.schema.items?.type, .number)
        XCTAssertEqual(schemaArrayDouble.schema.items?.minimum, 12.3)
        XCTAssertEqual(schemaArrayDouble.schema.items?.maximum, 45.6)
        
        let schemaArrayBool = try XCTUnwrap(llmFunction.schemaValueCollectors["boolArrayParameter"])
        XCTAssertEqual(schemaArrayBool.schema.type, .array)
        XCTAssertEqual(schemaArrayBool.schema.description, "Bool Array Parameter")
        XCTAssertEqual(schemaArrayBool.schema.items?.type, .boolean)
        XCTAssertEqual(schemaArrayBool.schema.items?.const, "true")
        
        let schemaArrayString = try XCTUnwrap(llmFunction.schemaValueCollectors["stringArrayParameter"])
        XCTAssertEqual(schemaArrayString.schema.type, .array)
        XCTAssertEqual(schemaArrayString.schema.description, "String Array Parameter")
        XCTAssertEqual(schemaArrayString.schema.items?.type, .string)
        XCTAssertEqual(schemaArrayString.schema.items?.pattern, "/d/d/d/d")
        XCTAssertEqual(schemaArrayString.schema.items?.enumValues, ["1234", "5678"])
        
        // Validate parameter injection
        let parameterData = try XCTUnwrap(
            JSONEncoder().encode(Parameters.shared)
        )
        
        try llmFunction.injectParameters(from: parameterData)
        let llmFunctionResponse = try await llmFunction.execute()
        XCTAssertEqual(llmFunctionResponse, "testArg")
    }
}
