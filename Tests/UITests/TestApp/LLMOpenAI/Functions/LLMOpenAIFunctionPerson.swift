//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziLLMOpenAI


struct LLMOpenAIFunctionPerson: LLMFunction {
    struct CustomArrayItemType: LLMFunctionParameterArrayElement {
        static let itemSchema: LLMFunctionParameterItemSchema = {
            guard let schema = try? LLMFunctionParameterItemSchema(
                .init(name: "firstName", type: .string, description: "The first name of the person"),
                .init(name: "lastName", type: .string, description: "The last name of the person")
            ) else {
                preconditionFailure("Couldn't create function calling schema definition for testing")
            }

            return schema
        }()

        let firstName: String
        let lastName: String
    }
    
    static let name: String = "get_age_persons"
    static let description: String = "Gets the age of persons."
    
    
    @Parameter(description: "Persons which age is to be determined.")
    var persons: [CustomArrayItemType]
    
    func execute() async throws -> String? {
        persons.reduce(into: "") { partialResult, person in
            partialResult += """
            First name: \(person.firstName) Last name: \(person.lastName) Age: \(Int.random(in: 20...70));
            """ + " "
        }
    }
}
