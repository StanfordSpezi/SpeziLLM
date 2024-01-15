//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziLLMOpenAI

// swiftlint:disable attributes
struct WeatherFunction: LLMFunction {
    static let name: String = "get_current_weather"
    static let description: String = "Get the current weather in a given location"
    
    let someArg: String
    
    
    @Parameter(description: "The city and state of the to be determined weather, e.g. San Francisco, CA")
    var location: String
    @Parameter(description: "The unit of the temperature", enumValues: ["fahrenheit", "celsius"])
    var unit: String?
    
    
    init(someArg: String) {
        self.someArg = someArg
    }
    
    
    func execute() async throws -> String {
        "The weather at \(location) is 30 degrees \(unit ?? "fahrenheit")"
    }
}
// swiftlint:enable attributes
