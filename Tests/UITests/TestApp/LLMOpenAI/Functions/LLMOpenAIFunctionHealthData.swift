//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziLLMOpenAI


struct LLMOpenAIFunctionHealthData: LLMFunction {
    static let name: String = "get_health_data"
    static let description: String = "Get the health data of a patient based on health data types."
    
    
    // swiftlint:disable attributes
    // FIXME: should be @Parameter
    @_LLMFunctionParameterWrapper(
        description: "The types of health data that are requested",
        enum: ["allergies", "medications", "preconditions"]
    )
    var healthDataTypes: [String]
    // swiftlint:enable attributes
    
    
    func execute() async throws -> String? {
        var healthData = ""
        
        if healthDataTypes.contains(where: { $0 == "allergies" }) {
            healthData += "The patient has an allergy against nuts. "
        }
        if healthDataTypes.contains(where: { $0 == "medications" }) {
            healthData += "The patient takes painkillers twice a day. "
        }
        if healthDataTypes.contains(where: { $0 == "preconditions" }) {
            healthData += "The patient has a depression. "
        }
        
        return healthData
    }
}
