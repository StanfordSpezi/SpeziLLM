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


struct LLMOpenAIFunctionPerson: LLMFunction {
    struct CustomArrayItemType: LLMFunctionParameterArrayItem {
        static let itemSchema: LLMFunctionParameterItemSchema = .init(
            type: .object,
            properties: [
                "firstName": .init(type: .string, description: "The first name of the person"),
                "lastName": .init(type: .string, description: "The last name of the person")
            ]
        )
        
        
        let firstName: String
        let lastName: String
    }
    
    static let name: String = "get_age_persons"
    static let description: String = "Gets the age of persons."
    
    
    // swiftlint:disable attributes
    @Parameter(description: "Persons which age is to be determined.")
    var persons: [CustomArrayItemType]
    // swiftlint:enable attributes
    
    func execute() async throws -> String? {
        persons.reduce(into: "") { partialResult, person in
            partialResult += """
            First name: \(person.firstName) Last name: \(person.lastName) Age: \(Int.random(in: 20...70));
            """ + " "
        }
    }
}
