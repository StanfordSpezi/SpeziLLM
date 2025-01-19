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
        @Parameter(description: "String Array Parameter", pattern: "/d/d/d/d", enum: ["1234", "5678"])
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
    
    let llm = LLMOpenAISchema(
        parameters: .init(modelType: .init(value1: "GPT 4 Turbo", value2: .gpt_hyphen_4_hyphen_turbo))
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
        var schema = schemaArrayInt.schema.value
        var items = schema["items"] as? [String: Any]
        XCTAssertEqual(schema["type"] as? String, "array")
        XCTAssertEqual(schema["description"] as? String, "Int Array Parameter")
        XCTAssertEqual(schema["minItems"] as? Int, 1)
        XCTAssertEqual(schema["maxItems"] as? Int, 9)
        XCTAssertTrue(schema["uniqueItems"] as? Bool ?? false)
        XCTAssertEqual(items?["type"] as? String, "integer")
        
        let schemaArrayDouble = try XCTUnwrap(llmFunction.schemaValueCollectors["doubleArrayParameter"])
        schema = schemaArrayDouble.schema.value
        items = schema["items"] as? [String: Any]
        XCTAssertEqual(schema["type"] as? String, "array")
        XCTAssertEqual(schema["description"] as? String, "Double Array Parameter")
        XCTAssertEqual(items?["type"] as? String, "number")
        XCTAssertEqual(items?["minimum"] as? Double, 12.3)
        XCTAssertEqual(items?["maximum"] as? Double, 45.6)
        
        let schemaArrayBool = try XCTUnwrap(llmFunction.schemaValueCollectors["boolArrayParameter"])
        schema = schemaArrayBool.schema.value
        items = schema["items"] as? [String: Any]
        XCTAssertEqual(schema["type"] as? String, "array")
        XCTAssertEqual(schema["description"] as? String, "Bool Array Parameter")
        XCTAssertEqual(items?["type"] as? String, "boolean")
        XCTAssertEqual(items?["const"] as? String, "true")
        
        let schemaArrayString = try XCTUnwrap(llmFunction.schemaValueCollectors["stringArrayParameter"])
        schema = schemaArrayString.schema.value
        items = schema["items"] as? [String: Any]
        XCTAssertEqual(schema["type"] as? String, "array")
        XCTAssertEqual(schema["description"] as? String, "String Array Parameter")
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
