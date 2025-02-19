//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziFoundation

// swiftlint:disable discouraged_optional_boolean discouraged_optional_collection

extension _LLMFunctionParameterWrapper where T: AnyArray, T.Element: BinaryInteger {
    /// Declares an `Int`-based ``LLMFunction/Parameter`` `array`.
    ///
    /// - Parameters:
    ///    - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    ///    - const: Specifies the constant `String`-based value of a certain parameter.
    ///    - multipleOf: Defines that the LLM parameter needs to be a multiple of the init argument.
    ///    - minimum: The minimum value of the parameter.
    ///    - maximum: The maximum value of the parameter.
    ///    - minItems: Defines the minimum amount of values in the `array`.
    ///    - maxItems: Defines the maximum amount of values in the `array`.
    ///    - uniqueItems: Specifies if all `array` elements need to be unique.
    public convenience init(
        description: some StringProtocol,
        const: (any StringProtocol)? = nil,
        multipleOf: Int? = nil,
        minimum: T.Element? = nil,
        maximum: T.Element? = nil,
        minItems: Int? = nil,
        maxItems: Int? = nil,
        uniqueItems: Bool? = nil
    ) {
        do {
            try self.init(schema: .init(unvalidatedValue: [
                "type": "array",
                "description": String(description),
                "items": [
                    "type": "integer",
                    "const": const.map { String($0) } as (any Sendable)?,
                    "multipleOf": multipleOf as (any Sendable)?,
                    "minimum": minimum.map { Double($0) } as (any Sendable)?,
                    "maximum": maximum.map { Double($0) } as (any Sendable)?
                ].compactMapValues { $0 },
                "minItems": minItems as (any Sendable)?,
                "maxItems": maxItems as (any Sendable)?,
                "uniqueItems": uniqueItems as (any Sendable)?
            ].compactMapValues { $0 }))
        } catch {
            preconditionFailure("SpeziLLMOpenAI: Failed to create validated function call schema definition of `LLMFunction/Parameter`: \(error)")
        }
    }
}

extension _LLMFunctionParameterWrapper where T: AnyArray, T.Element: BinaryFloatingPoint {
    /// Declares an `Float` or `Double` (`BinaryFloatingPoint`) -based ``LLMFunction/Parameter`` `array`.
    ///
    /// - Parameters:
    ///    - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    ///    - const: Specifies the constant `String`-based value of a certain parameter.
    ///    - minimum: The minimum value of the parameter.
    ///    - maximum: The maximum value of the parameter.
    ///    - minItems: Defines the minimum amount of values in the `array`.
    ///    - maxItems: Defines the maximum amount of values in the `array`.
    ///    - uniqueItems: Specifies if all `array` elements need to be unique.
    public convenience init(
        description: some StringProtocol,
        const: (any StringProtocol)? = nil,
        minimum: T.Element? = nil,
        maximum: T.Element? = nil,
        minItems: Int? = nil,
        maxItems: Int? = nil,
        uniqueItems: Bool? = nil
    ) {
        do {
            try self.init(schema: .init(unvalidatedValue: [
                "type": "array",
                "description": String(description),
                "items": [
                    "type": "number",
                    "const": const.map { String($0) } as (any Sendable)?,
                    "minimum": minimum.map { Double($0) } as (any Sendable)?,
                    "maximum": maximum.map { Double($0) } as (any Sendable)?
                ].compactMapValues { $0 },
                "minItems": minItems as (any Sendable)?,
                "maxItems": maxItems as (any Sendable)?,
                "uniqueItems": uniqueItems as (any Sendable)?
            ].compactMapValues { $0 }))
        } catch {
            preconditionFailure("SpeziLLMOpenAI: Failed to create validated function call schema definition of `LLMFunction/Parameter`: \(error)")
        }
    }
}

extension _LLMFunctionParameterWrapper where T: AnyArray, T.Element == Bool {
    /// Declares an `Bool`-based ``LLMFunction/Parameter`` `array`.
    ///
    /// - Parameters:
    ///    - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    ///    - const: Specifies the constant `String`-based value of a certain parameter.
    ///    - minItems: Defines the minimum amount of values in the `array`.
    ///    - maxItems: Defines the maximum amount of values in the `array`.
    ///    - uniqueItems: Specifies if all `array` elements need to be unique.
    public convenience init(
        description: some StringProtocol,
        const: (any StringProtocol)? = nil,
        minItems: Int? = nil,
        maxItems: Int? = nil,
        uniqueItems: Bool? = nil
    ) {
        do {
            try self.init(schema: .init(unvalidatedValue: [
                "type": "array",
                "description": String(description),
                "items": [
                    "type": "boolean",
                    "const": const.map { String($0) } as (any Sendable)?
                ].compactMapValues { $0 },
                "minItems": minItems as (any Sendable)?,
                "maxItems": maxItems as (any Sendable)?,
                "uniqueItems": uniqueItems as (any Sendable)?
            ].compactMapValues { $0 }))
        } catch {
            preconditionFailure("SpeziLLMOpenAI: Failed to create validated function call schema definition of `LLMFunction/Parameter`: \(error)")
        }
    }
}

extension _LLMFunctionParameterWrapper where T: AnyArray, T.Element: StringProtocol {
    /// Declares an `String`-based ``LLMFunction/Parameter`` `array`.
    ///
    /// - Parameters:
    ///    - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    ///    - pattern: A Regular Expression that the parameter needs to conform to.
    ///    - const: Specifies the constant `String`-based value of a certain parameter.
    ///    - enum: Defines all cases of a single `String` `array` element.
    ///    - minItems: Defines the minimum amount of values in the `array`.
    ///    - maxItems: Defines the maximum amount of values in the `array`.
    ///    - uniqueItems: Specifies if all `array` elements need to be unique.
    public convenience init(
        description: some StringProtocol,
        pattern: (any StringProtocol)? = nil,
        const: (any StringProtocol)? = nil,
        enum: [any StringProtocol]? = nil,
        minItems: Int? = nil,
        maxItems: Int? = nil,
        uniqueItems: Bool? = nil
    ) {
        do {
            try self.init(schema: .init(unvalidatedValue: [
                "type": "array",
                "description": String(description),
                "items": [
                    "type": "string",
                    "pattern": pattern.map { String($0) } as (any Sendable)?,
                    "const": const.map { String($0) } as (any Sendable)?,
                    "enum": `enum`.map { $0.map { String($0) } } as (any Sendable)?
                ].compactMapValues { $0 },
                "minItems": minItems as (any Sendable)?,
                "maxItems": maxItems as (any Sendable)?,
                "uniqueItems": uniqueItems as (any Sendable)?
            ].compactMapValues { $0 }))
        } catch {
            preconditionFailure("SpeziLLMOpenAI: Failed to create validated function call schema definition of `LLMFunction/Parameter`: \(error)")
        }
    }
}

// swiftlint:enable discouraged_optional_boolean discouraged_optional_collection
