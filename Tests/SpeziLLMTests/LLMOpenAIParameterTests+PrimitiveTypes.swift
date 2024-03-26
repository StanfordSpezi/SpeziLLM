//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

@testable import SpeziLLMOpenAI
import XCTest


final class LLMOpenAIParameterPrimitiveTypesTests: XCTestCase {
    struct Parameters: Encodable {
        static let shared = Self()
        
        let intParameter = 12
        let doubleParameter: Double = 12.34
        let boolParameter = true
        let stringParameter = "1234"
    }
    
    struct LLMFunctionTest: LLMFunction {
        static var name: String = "test_function"
        static var description: String = "This is a test LLM function."
        
        let someInitArg: String
        
        // swiftlint:disable attributes
        
        @Parameter(description: "Primitive Int Parameter", multipleOf: 3)
        var intParameter: Int
        @Parameter(description: "Primitive Double Parameter", minimum: 12.3, maximum: 34.56)
        var doubleParameter: Double
        @Parameter(description: "Primitive Bool Parameter", const: "false")
        var boolParameter: Bool
        @Parameter(description: "Primitive String Parameter", format: .datetime, pattern: "/d/d/d/d", enum: ["1234", "5678"])
        var stringParameter: String
        
        // swiftlint:enable attributes
        
        
        init(someInitArg: String) {
            self.someInitArg = someInitArg
        }
        
        
        func execute() async throws -> String? {
            XCTAssertEqual(intParameter, Parameters.shared.intParameter)
            XCTAssertEqual(doubleParameter, Parameters.shared.doubleParameter)
            XCTAssertEqual(boolParameter, Parameters.shared.boolParameter)
            XCTAssertEqual(stringParameter, Parameters.shared.stringParameter)
            
            return someInitArg
        }
    }
    
    let llm = LLMOpenAISchema(
        parameters: .init(modelType: .gpt4_turbo_preview)
    ) {
        LLMFunctionTest(someInitArg: "testArg")
    }
    
    func testLLMFunctionPrimitiveParameters() async throws {
        XCTAssertEqual(llm.functions.count, 1)
        let llmFunctionPair = try XCTUnwrap(llm.functions.first)
        
        // Validate parameter metadata
        XCTAssertEqual(llmFunctionPair.key, LLMFunctionTest.name)
        let llmFunction = llmFunctionPair.value
        XCTAssert(!(try XCTUnwrap(llmFunction.parameterValueCollectors["intParameter"])).isOptional)
        XCTAssert(!(try XCTUnwrap(llmFunction.parameterValueCollectors["doubleParameter"])).isOptional)
        XCTAssert(!(try XCTUnwrap(llmFunction.parameterValueCollectors["boolParameter"])).isOptional)
        XCTAssert(!(try XCTUnwrap(llmFunction.parameterValueCollectors["stringParameter"])).isOptional)
        
        // Validate parameter schema
        let schemaPrimitiveInt = try XCTUnwrap(llmFunction.schemaValueCollectors["intParameter"])
        XCTAssertEqual(schemaPrimitiveInt.schema.type, .integer)
        XCTAssertEqual(schemaPrimitiveInt.schema.description, "Primitive Int Parameter")
        XCTAssertEqual(schemaPrimitiveInt.schema.multipleOf, 3)
        
        let schemaPrimitiveDouble = try XCTUnwrap(llmFunction.schemaValueCollectors["doubleParameter"])
        XCTAssertEqual(schemaPrimitiveDouble.schema.type, .number)
        XCTAssertEqual(schemaPrimitiveDouble.schema.description, "Primitive Double Parameter")
        XCTAssertEqual(schemaPrimitiveDouble.schema.minimum, 12.3)
        XCTAssertEqual(schemaPrimitiveDouble.schema.maximum, 34.56)
        
        let schemaPrimitiveBool = try XCTUnwrap(llmFunction.schemaValueCollectors["boolParameter"])
        XCTAssertEqual(schemaPrimitiveBool.schema.type, .boolean)
        XCTAssertEqual(schemaPrimitiveBool.schema.description, "Primitive Bool Parameter")
        XCTAssertEqual(schemaPrimitiveBool.schema.const, "false")
        
        let schemaPrimitiveString = try XCTUnwrap(llmFunction.schemaValueCollectors["stringParameter"])
        XCTAssertEqual(schemaPrimitiveString.schema.type, .string)
        XCTAssertEqual(schemaPrimitiveString.schema.description, "Primitive String Parameter")
        XCTAssertEqual(schemaPrimitiveString.schema.format, "date-time")
        XCTAssertEqual(schemaPrimitiveString.schema.pattern, "/d/d/d/d")
        XCTAssertEqual(schemaPrimitiveString.schema.enum, ["1234", "5678"])
        
        // Validate parameter injection
        let parameterData = try XCTUnwrap(
            JSONEncoder().encode(Parameters.shared)
        )
        
        try llmFunction.injectParameters(from: parameterData)
        let llmFunctionResponse = try await llmFunction.execute()
        XCTAssertEqual(llmFunctionResponse, "testArg")
    }
}
