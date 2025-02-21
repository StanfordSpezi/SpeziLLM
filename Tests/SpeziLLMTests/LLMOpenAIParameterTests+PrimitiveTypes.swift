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

struct LLMOpenAIParameterPrimitiveTypesTests {
    struct Parameters: Encodable {
        static let shared = Self()
        
        let intParameter = 12
        let doubleParameter: Double = 12.34
        let boolParameter = true
        let stringParameter = "1234"
    }
    
    struct LLMFunctionTest: LLMFunction {
        static let name: String = "test_function"
        static let description: String = "This is a test LLM function."
        
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
            #expect(intParameter == Parameters.shared.intParameter)
            #expect(doubleParameter == Parameters.shared.doubleParameter)
            #expect(boolParameter == Parameters.shared.boolParameter)
            #expect(stringParameter == Parameters.shared.stringParameter)
            
            return someInitArg
        }
    }
    
    let llm = LLMOpenAISchema(
        parameters: .init(modelType: "gpt-4o")
    ) {
        LLMFunctionTest(someInitArg: "testArg")
    }
    
    @Test()
    func testLLMFunctionPrimitiveParameters() async throws {
        #expect(llm.functions.count == 1)
        let llmFunctionPair = try #require(llm.functions.first)
        
        // Validate parameter metadata
        #expect(llmFunctionPair.key == LLMFunctionTest.name)
        let llmFunction = llmFunctionPair.value
        #expect(!(try #require(llmFunction.parameterValueCollectors["intParameter"])).isOptional)
        #expect(!(try #require(llmFunction.parameterValueCollectors["doubleParameter"])).isOptional)
        #expect(!(try #require(llmFunction.parameterValueCollectors["boolParameter"])).isOptional)
        #expect(!(try #require(llmFunction.parameterValueCollectors["stringParameter"])).isOptional)
        
        // Validate parameter schema
        let schemaPrimitiveInt = try #require(llmFunction.schemaValueCollectors["intParameter"])
        #expect(schemaPrimitiveInt.schema.value["type"] as? String == "integer")
        #expect(schemaPrimitiveInt.schema.value["description"] as? String == "Primitive Int Parameter")
        #expect(schemaPrimitiveInt.schema.value["multipleOf"] as? Int == 3)
        
        let schemaPrimitiveDouble = try #require(llmFunction.schemaValueCollectors["doubleParameter"])
        #expect(schemaPrimitiveDouble.schema.value["type"] as? String == "number")
        #expect(schemaPrimitiveDouble.schema.value["description"] as? String == "Primitive Double Parameter")
        #expect(schemaPrimitiveDouble.schema.value["minimum"] as? Double == 12.3)
        #expect(schemaPrimitiveDouble.schema.value["maximum"] as? Double == 34.56)
        
        let schemaPrimitiveBool = try #require(llmFunction.schemaValueCollectors["boolParameter"])
        #expect(schemaPrimitiveBool.schema.value["type"] as? String == "boolean")
        #expect(schemaPrimitiveBool.schema.value["description"] as? String == "Primitive Bool Parameter")
        #expect(schemaPrimitiveBool.schema.value["const"] as? String == "false")
        
        let schemaPrimitiveString = try #require(llmFunction.schemaValueCollectors["stringParameter"])
        #expect(schemaPrimitiveString.schema.value["type"] as? String == "string")
        #expect(schemaPrimitiveString.schema.value["description"] as? String == "Primitive String Parameter")
        #expect(schemaPrimitiveString.schema.value["format"] as? String == "date-time")
        #expect(schemaPrimitiveString.schema.value["pattern"] as? String == "/d/d/d/d")
        #expect(schemaPrimitiveString.schema.value["enum"] as? [String] == ["1234", "5678"])
        
        // Validate parameter injection
        let parameterData = try #require(
            try JSONEncoder().encode(Parameters.shared)
        )
        
        try llmFunction.injectParameters(from: parameterData)
        let llmFunctionResponse = try await llmFunction.execute()
        #expect(llmFunctionResponse == "testArg")
    }
}
