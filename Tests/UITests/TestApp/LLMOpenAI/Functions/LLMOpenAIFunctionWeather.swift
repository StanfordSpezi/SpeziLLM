//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziLLMOpenAI


struct LLMOpenAIFunctionWeather: LLMFunction {
    enum TemperatureUnit: String, LLMFunctionParameterEnum {
        case celsius
        case fahrenheit
    }
    
    
    static let name: String = "get_current_weather"
    static let description: String = "Get the current weather in a given location"
    
    
    // swiftlint:disable attributes
    @Parameter(description: "The city and state of the to be determined weather, e.g. San Francisco, CA")
    var location: String
    @Parameter(description: "The unit of the temperature")
    var unit: TemperatureUnit
    // swiftlint:enable attributes
    
    
    func execute() async throws -> String? {
        "The weather at \(location) is 30 degrees \(unit)"
    }
}
