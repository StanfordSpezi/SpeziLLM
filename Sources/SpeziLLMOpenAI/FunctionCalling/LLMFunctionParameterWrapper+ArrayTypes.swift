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
    /// Creates an `Int`-based ``LLMFunction/Parameter`` `array`.
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
        description: any StringProtocol,
        const: (any StringProtocol)? = nil,
        multipleOf: (any BinaryInteger)? = nil,
        minimum: T.Element? = nil,
        maximum: T.Element? = nil,
        minItems: (any BinaryInteger)? = nil,
        maxItems: (any BinaryInteger)? = nil,
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
            minItems: minItems.map { Int($0) },
            maxItems: maxItems.map { Int($0) },
            uniqueItems: uniqueItems
        ))
    }
}

extension _LLMFunctionParameterWrapper where T: AnyArray, T.Element: BinaryFloatingPoint {
    /// Creates an `Float` or `Double` (`BinaryFloatingPoint`) -based ``LLMFunction/Parameter`` `array`.
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
        description: any StringProtocol,
        const: (any StringProtocol)? = nil,
        minimum: T.Element? = nil,
        maximum: T.Element? = nil,
        minItems: (any BinaryInteger)? = nil,
        maxItems: (any BinaryInteger)? = nil,
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
            minItems: minItems.map { Int($0) },
            maxItems: maxItems.map { Int($0) },
            uniqueItems: uniqueItems
        ))
    }
}

extension _LLMFunctionParameterWrapper where T: AnyArray, T.Element == Bool {
    /// Creates an `Bool`-based ``LLMFunction/Parameter`` `array`.
    ///
    /// - Parameters:
    ///    - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    ///    - const: Specifies the constant `String`-based value of a certain parameter.
    ///    - minItems: Defines the minimum amount of values in the `array`.
    ///    - maxItems: Defines the maximum amount of values in the `array`.
    ///    - uniqueItems: Specifies if all `array` elements need to be unique.
    public convenience init(
        description: any StringProtocol,
        const: (any StringProtocol)? = nil,
        minItems: (any BinaryInteger)? = nil,
        maxItems: (any BinaryInteger)? = nil,
        uniqueItems: Bool? = nil
    ) {
        self.init(schema: .init(
            type: .array,
            description: String(description),
            items: .init(
                type: .boolean,
                const: const.map { String($0) }
            ),
            minItems: minItems.map { Int($0) },
            maxItems: maxItems.map { Int($0) },
            uniqueItems: uniqueItems
        ))
    }
}

extension _LLMFunctionParameterWrapper where T: AnyArray, T.Element: StringProtocol {
    /// Creates an `String`-based ``LLMFunction/Parameter`` `array`.
    ///
    /// - Parameters:
    ///    - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    ///    - pattern: A Regular Expression that the parameter needs to conform to.
    ///    - const: Specifies the constant `String`-based value of a certain parameter.
    ///    - enumValues: Defines all cases of a single `String` `array` element.
    ///    - minItems: Defines the minimum amount of values in the `array`.
    ///    - maxItems: Defines the maximum amount of values in the `array`.
    ///    - uniqueItems: Specifies if all `array` elements need to be unique.
    public convenience init(
        description: any StringProtocol,
        pattern: (any StringProtocol)? = nil,
        const: (any StringProtocol)? = nil,
        enumValues: [any StringProtocol]? = nil,
        minItems: (any BinaryInteger)? = nil,
        maxItems: (any BinaryInteger)? = nil,
        uniqueItems: Bool? = nil
    ) {
        self.init(schema: .init(
            type: .array,
            description: String(description),
            items: .init(
                type: .string,
                pattern: pattern.map { String($0) },
                const: const.map { String($0) },
                enumValues: enumValues.map { $0.map { String($0) } }
            ),
            minItems: minItems.map { Int($0) },
            maxItems: maxItems.map { Int($0) },
            uniqueItems: uniqueItems
        ))
    }
}

// swiftlint:enable discouraged_optional_boolean discouraged_optional_collection
