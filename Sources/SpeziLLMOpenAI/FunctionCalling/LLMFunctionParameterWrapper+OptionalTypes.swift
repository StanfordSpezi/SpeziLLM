//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziFoundation

// swiftlint:disable discouraged_optional_boolean discouraged_optional_collection

extension _LLMFunctionParameterWrapper where T: AnyOptional, T.Wrapped: BinaryInteger {
    /// Declares an ``LLMFunction/Parameter`` of the type `Int?` defining a integer parameter of the ``LLMFunction``.
    ///
    /// - Parameters:
    ///    - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    ///    - const: Specifies the constant `String`-based value of a certain parameter.
    ///    - multipleOf: Defines that the LLM parameter needs to be a multiple of the init argument.
    ///    - minimum: The minimum value of the parameter.
    ///    - maximum: The maximum value of the parameter.
    public convenience init<D: StringProtocol>(
        description: D,
        const: (any StringProtocol)? = nil,
        multipleOf: Int? = nil,
        minimum: T.Wrapped? = nil,
        maximum: T.Wrapped? = nil
    ) {
        self.init(schema: .init(
            type: .integer,
            description: String(description),
            const: const.map { String($0) },
            multipleOf: multipleOf,
            minimum: minimum.map { Double($0) },
            maximum: maximum.map { Double($0) }
        ))
    }
}

extension _LLMFunctionParameterWrapper where T: AnyOptional, T.Wrapped: BinaryFloatingPoint {
    /// Declares an ``LLMFunction/Parameter`` of the type `Float?` or `Double?` (`FloatingPoint?`)  defining a floating-point parameter of the ``LLMFunction``.
    ///
    /// - Parameters:
    ///    - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    ///    - const: Specifies the constant `String`-based value of a certain parameter.
    ///    - minimum: The minimum value of the parameter.
    ///    - maximum: The maximum value of the parameter.
    public convenience init<D: StringProtocol>(
        description: D,
        const: (any StringProtocol)? = nil,
        minimum: T.Wrapped? = nil,
        maximum: T.Wrapped? = nil
    ) {
        self.init(schema: .init(
            type: .number,
            description: String(description),
            const: const.map { String($0) },
            minimum: minimum.map { Double($0) },
            maximum: maximum.map { Double($0) }
        ))
    }
}

extension _LLMFunctionParameterWrapper where T: AnyOptional, T.Wrapped == Bool {
    /// Declares an ``LLMFunction/Parameter`` of the type `Bool?` defining a binary parameter of the ``LLMFunction``.
    ///
    /// - Parameters:
    ///    - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    ///    - const: Specifies the constant `String`-based value of a certain parameter.
    public convenience init<D: StringProtocol>(
        description: D,
        const: (any StringProtocol)? = nil
    ) {
        self.init(schema: .init(
            type: .boolean,
            description: String(description),
            const: const.map { String($0) }
        ))
    }
}

extension _LLMFunctionParameterWrapper where T: AnyOptional, T.Wrapped: StringProtocol {
    /// Declares an ``LLMFunction/Parameter`` of the type `String?` defining a text-based parameter of the ``LLMFunction``.
    ///
    /// - Parameters:
    ///    - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    ///    - format: Defines a required format of the parameter, allowing interoperable semantic validation of the value.
    ///    - pattern: A Regular Expression that the parameter needs to conform to.
    ///    - const: Specifies the constant `String`-based value of a certain parameter.
    ///    - enum: Defines all cases of the `String` parameter.
    public convenience init<D: StringProtocol>(
        description: D,
        format: _LLMFunctionParameterWrapper.Format? = nil,
        pattern: (any StringProtocol)? = nil,
        const: (any StringProtocol)? = nil,
        enum: [any StringProtocol]? = nil
    ) {
        self.init(schema: .init(
            type: .string,
            description: String(description),
            format: format?.rawValue,
            pattern: pattern.map { String($0) },
            const: const.map { String($0) },
            enum: `enum`.map { $0.map { String($0) } }
        ))
    }
}

extension _LLMFunctionParameterWrapper where T: AnyOptional, T.Wrapped: AnyArray, T.Wrapped.Element: BinaryInteger {
    /// Declares an optional `Int`-based ``LLMFunction/Parameter`` `array`.
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
    public convenience init<D: StringProtocol>(
        description: D,
        const: (any StringProtocol)? = nil,
        multipleOf: Int? = nil,
        minimum: T.Wrapped.Element? = nil,
        maximum: T.Wrapped.Element? = nil,
        minItems: Int? = nil,
        maxItems: Int? = nil,
        uniqueItems: Bool? = nil
    ) {
        self.init(schema: .init(
            type: .array,
            description: String(description),
            items: .init(
                type: .integer,
                const: const.map { String($0) },
                multipleOf: multipleOf.map { Int($0) },
                minimum: minimum.map { Double($0) },
                maximum: maximum.map { Double($0) }
            ),
            minItems: minItems,
            maxItems: maxItems,
            uniqueItems: uniqueItems
        ))
    }
}

extension _LLMFunctionParameterWrapper where T: AnyOptional, T.Wrapped: AnyArray, T.Wrapped.Element: BinaryFloatingPoint {
    /// Declares an optional `Float` or `Double` (`BinaryFloatingPoint`) -based ``LLMFunction/Parameter`` `array`.
    ///
    /// - Parameters:
    ///    - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    ///    - const: Specifies the constant `String`-based value of a certain parameter.
    ///    - minimum: The minimum value of the parameter.
    ///    - maximum: The maximum value of the parameter.
    ///    - minItems: Defines the minimum amount of values in the `array`.
    ///    - maxItems: Defines the maximum amount of values in the `array`.
    ///    - uniqueItems: Specifies if all `array` elements need to be unique.
    public convenience init<D: StringProtocol>(
        description: D,
        const: (any StringProtocol)? = nil,
        minimum: T.Wrapped.Element? = nil,
        maximum: T.Wrapped.Element? = nil,
        minItems: Int? = nil,
        maxItems: Int? = nil,
        uniqueItems: Bool? = nil
    ) {
        self.init(schema: .init(
            type: .array,
            description: String(description),
            items: .init(
                type: .number,
                const: const.map { String($0) },
                minimum: minimum.map { Double($0) },
                maximum: maximum.map { Double($0) }
            ),
            minItems: minItems,
            maxItems: maxItems,
            uniqueItems: uniqueItems
        ))
    }
}

extension _LLMFunctionParameterWrapper where T: AnyOptional, T.Wrapped: AnyArray, T.Wrapped.Element == Bool {
    /// Declares an optional `Bool`-based ``LLMFunction/Parameter`` `array`.
    ///
    /// - Parameters:
    ///    - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    ///    - const: Specifies the constant `String`-based value of a certain parameter.
    ///    - minItems: Defines the minimum amount of values in the `array`.
    ///    - maxItems: Defines the maximum amount of values in the `array`.
    ///    - uniqueItems: Specifies if all `array` elements need to be unique.
    public convenience init<D: StringProtocol>(
        description: D,
        const: (any StringProtocol)? = nil,
        minItems: Int? = nil,
        maxItems: Int? = nil,
        uniqueItems: Bool? = nil
    ) {
        self.init(schema: .init(
            type: .array,
            description: String(description),
            items: .init(
                type: .boolean,
                const: const.map { String($0) }
            ),
            minItems: minItems,
            maxItems: maxItems,
            uniqueItems: uniqueItems
        ))
    }
}

extension _LLMFunctionParameterWrapper where T: AnyOptional, T.Wrapped: AnyArray, T.Wrapped.Element: StringProtocol {
    /// Declares an optional `String`-based ``LLMFunction/Parameter`` `array`.
    ///
    /// - Parameters:
    ///    - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    ///    - pattern: A Regular Expression that the parameter needs to conform to.
    ///    - const: Specifies the constant `String`-based value of a certain parameter.
    ///    - enum: Defines all cases of a single `String` `array` element.
    ///    - minItems: Defines the minimum amount of values in the `array`.
    ///    - maxItems: Defines the maximum amount of values in the `array`.
    ///    - uniqueItems: Specifies if all `array` elements need to be unique.
    public convenience init<D: StringProtocol>(
        description: D,
        pattern: (any StringProtocol)? = nil,
        const: (any StringProtocol)? = nil,
        enum: [any StringProtocol]? = nil,
        minItems: Int? = nil,
        maxItems: Int? = nil,
        uniqueItems: Bool? = nil
    ) {
        self.init(schema: .init(
            type: .array,
            description: String(description),
            items: .init(
                type: .string,
                pattern: pattern.map { String($0) },
                const: const.map { String($0) },
                enum: `enum`.map { $0.map { String($0) } }
            ),
            minItems: minItems,
            maxItems: maxItems,
            uniqueItems: uniqueItems
        ))
    }
}

// swiftlint:enable discouraged_optional_boolean discouraged_optional_collection
