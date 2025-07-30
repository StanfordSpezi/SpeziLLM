//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

extension _LLMFunctionParameterWrapper {
    /// Shared helper to build an `object` schema whose values are of the given JSON-Schema `type`.
    ///
    /// - Parameters:
    ///   - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    ///   - const: Specifies the constant `String`-based value of a certain parameter.
    ///   - valueType: The JSON-Schema type of the dictionary value
    ///                (e.g. `"integer"`, `"number"`, `"boolean"`, `"string"`).
    private convenience init(
        description: some StringProtocol,
        const: (any StringProtocol)?,
        valueType: LLMFunctionParameterItemSchema.Property.PropertyType
    ) {
        do {
            try self.init(schema: .init(unvalidatedValue: [
                "type": "object",
                "description": String(description),
                "properties": [:] as [String: any Sendable],
                "const": const.map { String($0) } as (any Sendable)?,
                "additionalProperties": ["type": valueType.rawValue]
            ].compactMapValues { $0 }))
        } catch {
            preconditionFailure(
              "SpeziLLMOpenAI: Failed to create validated function call schema definition of `LLMFunction/Parameter`: \(error)"
            )
        }
    }
}

extension _LLMFunctionParameterWrapper where T: ExpressibleByDictionaryLiteral,
                                             T.Key: StringProtocol & Hashable,
                                             T.Value: BinaryInteger {
    /// Declares a ``LLMFunction/Parameter``  of type `object`
    /// representing a dictionary with `String`-based keys and `Int`-based values.
    ///
    /// - Parameters:
    ///    - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    ///    - const: Specifies the constant `String`-based value of a certain parameter.
    public convenience init(
        description: some StringProtocol,
        const: (any StringProtocol)? = nil
    ) {
        self.init(description: description, const: const, valueType: .integer)
    }
}

extension _LLMFunctionParameterWrapper where T: ExpressibleByDictionaryLiteral,
                                             T.Key: StringProtocol & Hashable,
                                             T.Value: BinaryFloatingPoint {
    /// Declares a ``LLMFunction/Parameter``  of type `object`
    /// representing a dictionary with `String`-based keys and `Float` or `Double` (`BinaryFloatingPoint`) -based values.
    ///
    /// - Parameters:
    ///    - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    ///    - const: Specifies the constant `String`-based value of a certain parameter.
    public convenience init(
        description: some StringProtocol,
        const: (any StringProtocol)? = nil
    ) {
        self.init(description: description, const: const, valueType: .number)
    }
}

extension _LLMFunctionParameterWrapper where T: ExpressibleByDictionaryLiteral,
                                             T.Key: StringProtocol & Hashable,
                                             T.Value == Bool {
    /// Declares a ``LLMFunction/Parameter``  of type `object`
    /// representing a dictionary with `String`-based keys and `boolean` values.
    ///
    /// - Parameters:
    ///    - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    ///    - const: Specifies the constant `String`-based value of a certain parameter.
    public convenience init(
        description: some StringProtocol,
        const: (any StringProtocol)? = nil
    ) {
        self.init(description: description, const: const, valueType: .boolean)
    }
}


extension _LLMFunctionParameterWrapper where T: ExpressibleByDictionaryLiteral,
                                             T.Key: StringProtocol & Hashable,
                                             T.Value: StringProtocol {
    /// Declares a ``LLMFunction/Parameter``  of type `object`
    /// representing a dictionary with `String`-based keys and `String`-based values.
    ///
    /// - Parameters:
    ///    - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    ///    - const: Specifies the constant `String`-based value of a certain parameter.
    ///    - pattern: A Regular Expression that the keys of the objects needs to conform to.
    public convenience init(
        description: some StringProtocol,
        const: (any StringProtocol)? = nil
    ) {
        self.init(description: description, const: const, valueType: .string)
    }
}
