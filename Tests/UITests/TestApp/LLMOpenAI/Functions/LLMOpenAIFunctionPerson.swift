//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import OpenAPIRuntime
import SpeziLLMOpenAI


struct LLMOpenAIFunctionPerson: LLMFunction {
    struct CustomArrayItemType: LLMFunctionParameterArrayElement {
        static let itemSchema: Components.Schemas.FunctionParameters = {
            do {
                return try Components.Schemas.FunctionParameters(additionalProperties: .init(unvalidatedValue: [
                    "type": "object",
                    "properties": [
                        "firstName": [
                            "type": "string",
                            "description": "The first name of the person"
                        ],
                        "lastName": [
                            "type": "string",
                            "description": "The last name of the person"
                        ]
                    ]
                ]))
            } catch {
                fatalError("Couldn't create function parameters in for testing")
            }
        }()
                
        let firstName: String
        let lastName: String
    }
    
    static let name: String = "get_age_persons"
    static let description: String = "Gets the age of persons."
    
    
    // swiftlint:disable attributes
    @_LLMFunctionParameterWrapper(description: "Persons which age is to be determined.")
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
