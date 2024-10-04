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
        parameters: .init(modelType: .init(value1: .gpt4_turbo, value2: .gpt_hyphen_4_hyphen_turbo))
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
        var schema = schemaOptionalInt.schema.value
        XCTAssertEqual(schema["type"] as? String, "integer")
        XCTAssertEqual(schema["description"] as? String, "Optional Int Parameter")
        XCTAssertEqual(schema["multipleOf"] as? Int, 3)
        
        let schemaOptionalDouble = try XCTUnwrap(llmFunction.schemaValueCollectors["doubleParameter"])
        schema = schemaOptionalDouble.schema.value
        XCTAssertEqual(schema["type"] as? String, "number")
        XCTAssertEqual(schema["description"] as? String, "Optional Double Parameter")
        XCTAssertEqual(schema["minimum"] as? Double, 12)
        XCTAssertEqual(schema["maximum"] as? Double, 34)
        
        let schemaOptionalBool = try XCTUnwrap(llmFunction.schemaValueCollectors["boolParameter"])
        schema = schemaOptionalBool.schema.value
        XCTAssertEqual(schema["type"] as? String, "boolean")
        XCTAssertEqual(schema["description"] as? String, "Optional Bool Parameter")
        XCTAssertEqual(schema["const"] as? String, "false")
        
        let schemaOptionalString = try XCTUnwrap(llmFunction.schemaValueCollectors["stringParameter"])
        schema = schemaOptionalString.schema.value
        XCTAssertEqual(schema["type"] as? String, "string")
        XCTAssertEqual(schema["description"] as? String, "Optional String Parameter")
        XCTAssertEqual(schema["format"] as? String, "date-time")
        XCTAssertEqual(schema["pattern"] as? String, "/d/d/d/d")
        XCTAssertEqual(schema["enum"] as? [String], ["1234", "5678"])
        
        let schemaArrayInt = try XCTUnwrap(llmFunction.schemaValueCollectors["intArrayParameter"])
        schema = schemaArrayInt.schema.value
        var items = schema["items"] as? [String: Any]
        XCTAssertEqual(schema["type"] as? String, "array")
        XCTAssertEqual(schema["description"] as? String, "Optional Int Array Parameter")
        XCTAssertEqual(schema["minItems"] as? Int, 1)
        XCTAssertEqual(schema["maxItems"] as? Int, 9)
        XCTAssertTrue(schema["uniqueItems"] as? Bool ?? false)
        XCTAssertEqual(items?["type"] as? String, "integer")
        
        let schemaArrayDouble = try XCTUnwrap(llmFunction.schemaValueCollectors["doubleArrayParameter"])
        schema = schemaArrayDouble.schema.value
        items = schema["items"] as? [String: Any]
        XCTAssertEqual(schema["type"] as? String, "array")
        XCTAssertEqual(schema["description"] as? String, "Optional Double Array Parameter")
        XCTAssertEqual(items?["type"] as? String, "number")
        XCTAssertEqual(items?["minimum"] as? Double, 12.3)
        XCTAssertEqual(items?["maximum"] as? Double, 45.6)
        
        let schemaArrayBool = try XCTUnwrap(llmFunction.schemaValueCollectors["boolArrayParameter"])
        schema = schemaArrayBool.schema.value
        items = schema["items"] as? [String: Any]
        XCTAssertEqual(schema["type"] as? String, "array")
        XCTAssertEqual(schema["description"] as? String, "Optional Bool Array Parameter")
        XCTAssertEqual(items?["type"] as? String, "boolean")
        XCTAssertEqual(items?["const"] as? String, "true")
        
        let schemaArrayString = try XCTUnwrap(llmFunction.schemaValueCollectors["stringArrayParameter"])
        schema = schemaArrayString.schema.value
        items = schema["items"] as? [String: Any]
        XCTAssertEqual(schema["type"] as? String, "array")
        XCTAssertEqual(schema["description"] as? String, "Optional String Array Parameter")
        XCTAssertEqual(items?["type"] as? String, "string")
        XCTAssertEqual(items?["pattern"] as? String, "/d/d/d/d")
        XCTAssertEqual(items?["enum"] as? [String], ["1234", "5678"])
        
        // Validate parameter injection
        let parameterData = try XCTUnwrap(
            JSONEncoder().encode(Parameters.shared)
        )
        
        try llmFunction.injectParameters(from: parameterData)
        let llmFunctionResponse = try await llmFunction.execute()
        XCTAssertEqual(llmFunctionResponse, "testArg")
    }
}
