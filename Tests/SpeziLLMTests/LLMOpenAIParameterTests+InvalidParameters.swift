//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

@testable import SpeziLLMOpenAI
import XCTest


final class LLMOpenAIInvalidParametersTests: XCTestCase {
    struct Parameters: Encodable {
        static let shared = Self()
        
        let intParameter = 12
    }
    
    struct LLMFunctionTest: LLMFunction {
        static let name: String = "test_invalid_parameters_function"
        static let description: String = "This is a test invalid parameters LLM function."
        
        let someInitArg: String
        
        // swiftlint:disable attributes
        
        @Parameter(description: "Random Parameter", pattern: "/d/d/d/d")
        var randomParameter: String
        
        // swiftlint:enable attributes
        
        
        init(someInitArg: String) {
            self.someInitArg = someInitArg
        }
        
        
        func execute() async throws -> String? {
            XCTFail("Execution of function should have never happened as parameters mismatch!")
            
            return someInitArg
        }
    }
    
    let llm = LLMOpenAISchema(
        parameters: .init(modelType: "gpt-4o")
    ) {
        LLMFunctionTest(someInitArg: "testArg")
    }
    
    func testLLMFunctionPrimitiveParameters() async throws {
        XCTAssertEqual(llm.functions.count, 1)
        let llmFunctionPair = try XCTUnwrap(llm.functions.first)
        
        // Validate parameter metadata
        XCTAssertEqual(llmFunctionPair.key, LLMFunctionTest.name)
        let llmFunction = llmFunctionPair.value
        XCTAssert(!(try XCTUnwrap(llmFunction.parameterValueCollectors["randomParameter"])).isOptional)
        
        // Validate parameter schema
        let schemaRandomParameter = try XCTUnwrap(llmFunction.schemaValueCollectors["randomParameter"])
        let schema = schemaRandomParameter.schema.value
        XCTAssertEqual(schema["type"] as? String, "string")
        XCTAssertEqual(schema["description"] as? String, "Random Parameter")
        XCTAssertEqual(schema["pattern"] as? String, "/d/d/d/d")
        
        // Validate parameter injection
        let parameterData = try XCTUnwrap(
            JSONEncoder().encode(Parameters.shared)
        )
        
        XCTAssertThrowsError(
            try llmFunction.injectParameters(from: parameterData),
            "Mismatch between the defined values of the LLM Function and the requested values by the LLM"
        )
    }
}
