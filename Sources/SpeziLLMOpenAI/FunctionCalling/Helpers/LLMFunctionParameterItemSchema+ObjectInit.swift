//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import OpenAPIRuntime


/// Convenience extension to initialize a simple one-level object-based function calling schema definition.
extension LLMFunctionParameterItemSchema {
    public struct Property: Sendable {
        public enum PropertyType: String, Sendable {
            case integer
            case string
            case boolean
            case number
            case null
        }


        let name: String
        let type: PropertyType
        let description: String


        /// Initializes a ``LLMFunctionParameterItemSchema/Property``.
        ///
        /// - Parameters:
        ///   - name: The name of the parameter.
        ///   - type: The type of the parameter, see ``LLMFunctionParameterItemSchema/Property/PropertyType``.
        ///   - description: The description of the parameter.
        public init(name: String, type: PropertyType, description: String) {
            self.name = name
            self.type = type
            self.description = description
        }
    }


    /// Initialize a simple, one-level, object-based ``LLMFunctionParameterItemSchema``.
    /// - Parameter objectProperties: The ``LLMFunctionParameterItemSchema/Property``s of the schema.
    public init(_ objectProperties: Property...) throws {
        try self.init(objectProperties)
    }

    /// Initialize a simple, one-level, object-based ``LLMFunctionParameterItemSchema``.
    /// - Parameter objectProperties: The ``LLMFunctionParameterItemSchema/Property``s of the schema.
    public init(_ objectProperties: [Property]) throws {
        try self.init(
            unvalidatedValue: [
                "type": "object",
                "properties": objectProperties.reduce(into: [String: (any Sendable)?]()) { result, property in
                    result[property.name] = [
                        "type": property.type.rawValue,
                        "description": property.description
                    ]
                }
            ]
        )
    }
}
