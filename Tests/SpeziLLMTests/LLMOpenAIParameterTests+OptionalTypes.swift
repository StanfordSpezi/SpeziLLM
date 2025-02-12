//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

@testable import SpeziLLMOpenAI
import XCTest


final class LLMOpenAIParameterOptionalTypesTests: XCTestCase {
    struct Parameters: Encodable {
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
    
    struct LLMFunctionTest: LLMFunction {
        static var name: String = "test_optional_function"
        static var description: String = "This is a test optional LLM function."
        
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
            XCTAssertEqual(intParameter, Parameters.shared.intParameter)
            XCTAssertEqual(doubleParameter, Parameters.shared.doubleParameter)
            XCTAssertEqual(boolParameter, Parameters.shared.boolParameter)
            XCTAssertEqual(stringParameter, Parameters.shared.stringParameter)
            XCTAssertEqual(intArrayParameter, Parameters.shared.intArrayParameter)
            XCTAssertEqual(doubleArrayParameter, Parameters.shared.doubleArrayParameter)
            XCTAssertEqual(boolArrayParameter, Parameters.shared.boolArrayParameter)
            XCTAssertEqual(stringArrayParameter, Parameters.shared.stringArrayParameter)
            XCTAssertNil(arrayNilParameter)
            
            return someInitArg
        }
    }
    
    let llm = LLMOpenAISchema(
        parameters: .init(modelType: .gpt4_o)
    ) {
        LLMFunctionTest(someInitArg: "testArg")
    }
    
    func testLLMFunctionOptionalParameters() async throws { // swiftlint:disable:this function_body_length
        XCTAssertEqual(llm.functions.count, 1)
        let llmFunctionPair = try XCTUnwrap(llm.functions.first)
        
        // Validate parameter metadata
        XCTAssertEqual(llmFunctionPair.key, LLMFunctionTest.name)
        let llmFunction = llmFunctionPair.value
        XCTAssert(try XCTUnwrap(llmFunction.parameterValueCollectors["intParameter"]).isOptional)
        XCTAssert(try XCTUnwrap(llmFunction.parameterValueCollectors["doubleParameter"]).isOptional)
        XCTAssert(try XCTUnwrap(llmFunction.parameterValueCollectors["boolParameter"]).isOptional)
        XCTAssert(try XCTUnwrap(llmFunction.parameterValueCollectors["stringParameter"]).isOptional)
        XCTAssert(try XCTUnwrap(llmFunction.parameterValueCollectors["intArrayParameter"]).isOptional)
        XCTAssert(try XCTUnwrap(llmFunction.parameterValueCollectors["doubleArrayParameter"]).isOptional)
        XCTAssert(try XCTUnwrap(llmFunction.parameterValueCollectors["boolArrayParameter"]).isOptional)
        XCTAssert(try XCTUnwrap(llmFunction.parameterValueCollectors["stringArrayParameter"]).isOptional)
        XCTAssert(try XCTUnwrap(llmFunction.parameterValueCollectors["arrayNilParameter"]).isOptional)
        
        // Validate parameter schema
        let schemaOptionalInt = try XCTUnwrap(llmFunction.schemaValueCollectors["intParameter"])
        XCTAssertEqual(schemaOptionalInt.schema.type, .integer)
        XCTAssertEqual(schemaOptionalInt.schema.description, "Optional Int Parameter")
        XCTAssertEqual(schemaOptionalInt.schema.multipleOf, 3)
        
        let schemaOptionalDouble = try XCTUnwrap(llmFunction.schemaValueCollectors["doubleParameter"])
        XCTAssertEqual(schemaOptionalDouble.schema.type, .number)
        XCTAssertEqual(schemaOptionalDouble.schema.description, "Optional Double Parameter")
        XCTAssertEqual(schemaOptionalDouble.schema.minimum, 12)
        XCTAssertEqual(schemaOptionalDouble.schema.maximum, 34)
        
        let schemaOptionalBool = try XCTUnwrap(llmFunction.schemaValueCollectors["boolParameter"])
        XCTAssertEqual(schemaOptionalBool.schema.type, .boolean)
        XCTAssertEqual(schemaOptionalBool.schema.description, "Optional Bool Parameter")
        XCTAssertEqual(schemaOptionalBool.schema.const, "false")
        
        let schemaOptionalString = try XCTUnwrap(llmFunction.schemaValueCollectors["stringParameter"])
        XCTAssertEqual(schemaOptionalString.schema.type, .string)
        XCTAssertEqual(schemaOptionalString.schema.description, "Optional String Parameter")
        XCTAssertEqual(schemaOptionalString.schema.format, "date-time")
        XCTAssertEqual(schemaOptionalString.schema.pattern, "/d/d/d/d")
        XCTAssertEqual(schemaOptionalString.schema.enum, ["1234", "5678"])
        
        let schemaArrayInt = try XCTUnwrap(llmFunction.schemaValueCollectors["intArrayParameter"])
        XCTAssertEqual(schemaArrayInt.schema.type, .array)
        XCTAssertEqual(schemaArrayInt.schema.description, "Optional Int Array Parameter")
        XCTAssertEqual(schemaArrayInt.schema.minItems, 1)
        XCTAssertEqual(schemaArrayInt.schema.maxItems, 9)
        XCTAssertTrue(schemaArrayInt.schema.uniqueItems ?? false)
        XCTAssertEqual(schemaArrayInt.schema.items?.type, .integer)
        
        let schemaArrayDouble = try XCTUnwrap(llmFunction.schemaValueCollectors["doubleArrayParameter"])
        XCTAssertEqual(schemaArrayDouble.schema.type, .array)
        XCTAssertEqual(schemaArrayDouble.schema.description, "Optional Double Array Parameter")
        XCTAssertEqual(schemaArrayDouble.schema.items?.type, .number)
        XCTAssertEqual(schemaArrayDouble.schema.items?.minimum, 12.3)
        XCTAssertEqual(schemaArrayDouble.schema.items?.maximum, 45.6)
        
        let schemaArrayBool = try XCTUnwrap(llmFunction.schemaValueCollectors["boolArrayParameter"])
        XCTAssertEqual(schemaArrayBool.schema.type, .array)
        XCTAssertEqual(schemaArrayBool.schema.description, "Optional Bool Array Parameter")
        XCTAssertEqual(schemaArrayBool.schema.items?.type, .boolean)
        XCTAssertEqual(schemaArrayBool.schema.items?.const, "true")
        
        let schemaArrayString = try XCTUnwrap(llmFunction.schemaValueCollectors["stringArrayParameter"])
        XCTAssertEqual(schemaArrayString.schema.type, .array)
        XCTAssertEqual(schemaArrayString.schema.description, "Optional String Array Parameter")
        XCTAssertEqual(schemaArrayString.schema.items?.type, .string)
        XCTAssertEqual(schemaArrayString.schema.items?.pattern, "/d/d/d/d")
        XCTAssertEqual(schemaArrayString.schema.items?.enum, ["1234", "5678"])
        
        // Validate parameter injection
        let parameterData = try XCTUnwrap(
            JSONEncoder().encode(Parameters.shared)
        )
        
        try llmFunction.injectParameters(from: parameterData)
        let llmFunctionResponse = try await llmFunction.execute()
        XCTAssertEqual(llmFunctionResponse, "testArg")
    }
}
