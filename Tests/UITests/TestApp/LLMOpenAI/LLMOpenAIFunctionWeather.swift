//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import OpenAI
import SpeziLLMOpenAI

// swiftlint:disable attributes

struct WeatherFunction: LLMFunction {
    enum TemperatureUnit: String, LLMFunctionParameterEnum {
        case test1
        case test2
    }
    
    struct CustomType: LLMFunctionParameter {
        static var schema: LLMFunctionParameterPropertySchema = .init(type: .null)
        
        let name: String
        let world: String
    }
    
    struct TemperatureUnit2: LLMFunctionParameterArrayItem {
        static var itemSchema: LLMFunctionParameterItemSchema = .init(
            type: .object,
            properties: [
                "test1": .init(type: .string),
                "test2": .init(type: .string)
            ]
        )
        
        let test1: String
        let test2: String
    }
    
    static let name: String = "get_current_weather"
    static let description: String = "Get the current weather in a given location"
    
    let someArg: String
    
    
    @Parameter(description: "The city and state of the to be determined weather, e.g. San Francisco, CA")
    var location: String
    
    
    @Parameter(description: "Enum", const: "")
    var unit: TemperatureUnit
    @Parameter(description: "Enum Optional", const: "")
    var unit1: TemperatureUnit?
    @Parameter(description: "Int Optional")
    var unit3: Int?
    @Parameter(description: "ArrayParameterPrimitive", maxItems: 3)
    var arrayParameterPrimitive: [String]
    @Parameter(description: "ArrayParameterPrimitiveOptional", maxItems: 3)
    var arrayParameterPrimitiveOptional: [String]?
    
    
    @Parameter(description: "ArrayParameterCustomType", maxItems: 3)
    var arrayParameterCustomType: [TemperatureUnit2]
    @Parameter(description: "ArrayParameterCustomTypeOptional", maxItems: 3)
    var arrayParameterCustomTypeOptional: [TemperatureUnit2]?
    
    
    init(someArg: String) {
        self.someArg = someArg
    }
    
    
    func execute() async throws -> String {
        "The weather at \(location) is 30 degrees \(unit1?.rawValue ?? "fahrenheit")"
    }
}

// swiftlint:enable attributes
