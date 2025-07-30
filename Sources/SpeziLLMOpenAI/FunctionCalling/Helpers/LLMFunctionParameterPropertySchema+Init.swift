//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import OpenAPIRuntime


/// Convenience extension to initialize a simple object-type function calling schema definition.
extension LLMFunctionParameterPropertySchema {
    /// Initialize a simple, object-type ``LLMFunctionParameterPropertySchema``.
    /// - Parameter type: The type of the ``LLMFunctionParameterPropertySchema``.
    public init(type: Property.PropertyType) throws {
        try self.init(
            unvalidatedValue: [
                "type": type.rawValue
            ]
        )
    }
}
