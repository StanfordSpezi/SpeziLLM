//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

@testable import SpeziLLM
@testable import SpeziLLMOpenAI
import XCTest

final class LLMOpenAIParameterEnumTests: XCTestCase {
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
        static var name: String = "test_enum_function"
        static var description: String = "This is a test enum LLM function."
        
        let someInitArg: String
        
        // swiftlint:disable attributes
        
        @Parameter(description: "Enum Parameter", const: "optionA")
        var enumParameter: CustomEnumType
        @Parameter(description: "Optional Enum Parameter")
        var optionalEnumParameter: CustomEnumType?
        @Parameter(description: "Array Enum Parameter", minItems: 1, maxItems: 5, uniqueItems: false)
        var arrayEnumParameter: [CustomEnumType]
        @Parameter(description: "Optional Array Enum Parameter")
        var optionalArrayEnumParameter: [CustomEnumType]?
        
        // swiftlint:enable attributes
        
        
        init(someInitArg: String) {
            self.someInitArg = someInitArg
        }
        
        
        func execute() async throws -> String? {
            XCTAssertEqual(enumParameter, Parameters.shared.enumParameter)
            XCTAssertEqual(optionalEnumParameter, Parameters.shared.optionalEnumParameter)
            XCTAssertEqual(arrayEnumParameter, Parameters.shared.arrayEnumParameter)
            XCTAssertEqual(optionalArrayEnumParameter, Parameters.shared.optionalArrayEnumParameter)
            
            return someInitArg
        }
    }
    
    let llm = LLMOpenAI(
        parameters: .init(modelType: .gpt4_1106_preview),
        functions: [
            LLMFunctionTest(someInitArg: "testArg")
        ]
    )
    
    func testLLMFunctionPrimitiveParameters() async throws {
        XCTAssertEqual(llm.functions.count, 1)
        let llmFunctionPair = try XCTUnwrap(llm.functions.first)
        
        // Validate parameter metadata
        XCTAssertEqual(llmFunctionPair.key, LLMFunctionTest.name)
        let llmFunction = llmFunctionPair.value
        XCTAssert(!(try XCTUnwrap(llmFunction.parameterValueCollectors["enumParameter"])).isOptional)
        XCTAssert(try XCTUnwrap(llmFunction.parameterValueCollectors["optionalEnumParameter"]).isOptional)
        XCTAssert(!(try XCTUnwrap(llmFunction.parameterValueCollectors["arrayEnumParameter"])).isOptional)
        XCTAssert(try XCTUnwrap(llmFunction.parameterValueCollectors["optionalArrayEnumParameter"]).isOptional)
        
        // Validate parameter schema
        let schemaPrimitiveInt = try XCTUnwrap(llmFunction.schemaValueCollectors["enumParameter"])
        XCTAssertEqual(schemaPrimitiveInt.schema.type, .string)
        XCTAssertEqual(schemaPrimitiveInt.schema.description, "Enum Parameter")
        XCTAssertEqual(schemaPrimitiveInt.schema.const, "optionA")
        XCTAssertEqual(schemaPrimitiveInt.schema.enumValues, CustomEnumType.allCases.map { $0.rawValue })
        
        let schemaPrimitiveDouble = try XCTUnwrap(llmFunction.schemaValueCollectors["optionalEnumParameter"])
        XCTAssertEqual(schemaPrimitiveDouble.schema.type, .string)
        XCTAssertEqual(schemaPrimitiveDouble.schema.description, "Optional Enum Parameter")
        XCTAssertEqual(schemaPrimitiveDouble.schema.enumValues, CustomEnumType.allCases.map { $0.rawValue })
        
        let schemaPrimitiveBool = try XCTUnwrap(llmFunction.schemaValueCollectors["arrayEnumParameter"])
        XCTAssertEqual(schemaPrimitiveBool.schema.type, .array)
        XCTAssertEqual(schemaPrimitiveBool.schema.description, "Array Enum Parameter")
        XCTAssertEqual(schemaPrimitiveBool.schema.minItems, 1)
        XCTAssertEqual(schemaPrimitiveBool.schema.maxItems, 5)
        XCTAssertEqual(schemaPrimitiveBool.schema.uniqueItems, false)
        XCTAssertEqual(schemaPrimitiveBool.schema.items?.type, .string)
        XCTAssertEqual(schemaPrimitiveBool.schema.items?.enumValues, CustomEnumType.allCases.map { $0.rawValue })
        
        let schemaPrimitiveString = try XCTUnwrap(llmFunction.schemaValueCollectors["optionalArrayEnumParameter"])
        XCTAssertEqual(schemaPrimitiveString.schema.type, .array)
        XCTAssertEqual(schemaPrimitiveString.schema.description, "Optional Array Enum Parameter")
        XCTAssertEqual(schemaPrimitiveString.schema.items?.type, .string)
        XCTAssertEqual(schemaPrimitiveString.schema.items?.enumValues, CustomEnumType.allCases.map { $0.rawValue })
        
        // Validate parameter injection
        let parameterData = try XCTUnwrap(
            JSONEncoder().encode(Parameters.shared)
        )
        
        try llmFunction.injectParameters(from: parameterData)
        let llmFunctionResponse = try await llmFunction.execute()
        XCTAssertEqual(llmFunctionResponse, "testArg")
    }
}
