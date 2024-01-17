//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziFoundation

// swiftlint:disable discouraged_optional_boolean discouraged_optional_collection

extension _LLMFunctionParameterWrapper where T == [Int] {
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
        description: String,
        const: (any CustomStringConvertible)? = nil,
        multipleOf: Int? = nil,
        minimum: Int? = nil,
        maximum: Int? = nil,
        minItems: Int? = nil,
        maxItems: Int? = nil,
        uniqueItems: Bool? = nil
    ) {
        self.init(description: .init())
        let minimum: Double? = if let minimum { Double(minimum) } else { nil }
        let maximum: Double? = if let maximum { Double(maximum) } else { nil }
        self.schema = .init(
            type: T.schema.type,
            description: description,
            items: .init(
                type: T.Element.schema.type,
                const: const?.description,
                multipleOf: multipleOf,
                minimum: minimum,
                maximum: maximum
            ),
            minItems: minItems,
            maxItems: maxItems,
            uniqueItems: uniqueItems
        )
    }
}

extension _LLMFunctionParameterWrapper where T == [Float] {
    /// Creates an `Float`-based ``LLMFunction/Parameter`` `array`.
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
        description: String,
        const: (any CustomStringConvertible)? = nil,
        minimum: Float? = nil,
        maximum: Float? = nil,
        minItems: Int? = nil,
        maxItems: Int? = nil,
        uniqueItems: Bool? = nil
    ) {
        self.init(description: .init())
        let minimum: Double? = if let minimum { Double(minimum) } else { nil }
        let maximum: Double? = if let maximum { Double(maximum) } else { nil }
        self.schema = .init(
            type: T.schema.type,
            description: description,
            items: .init(
                type: T.Element.schema.type,
                const: const?.description,
                minimum: minimum,
                maximum: maximum
            ),
            minItems: minItems,
            maxItems: maxItems,
            uniqueItems: uniqueItems
        )
    }
}

extension _LLMFunctionParameterWrapper where T == [Double] {
    /// Creates an `Double`-based ``LLMFunction/Parameter`` `array`.
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
        description: String,
        const: (any CustomStringConvertible)? = nil,
        minimum: Double? = nil,
        maximum: Double? = nil,
        minItems: Int? = nil,
        maxItems: Int? = nil,
        uniqueItems: Bool? = nil
    ) {
        self.init(description: .init())
        self.schema = .init(
            type: T.schema.type,
            description: description,
            items: .init(
                type: T.Element.schema.type,
                const: const?.description,
                minimum: minimum,
                maximum: maximum
            ),
            minItems: minItems,
            maxItems: maxItems,
            uniqueItems: uniqueItems
        )
    }
}

extension _LLMFunctionParameterWrapper where T == [Bool] {
    /// Creates an `Bool`-based ``LLMFunction/Parameter`` `array`.
    ///
    /// - Parameters:
    ///    - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    ///    - const: Specifies the constant `String`-based value of a certain parameter.
    ///    - minItems: Defines the minimum amount of values in the `array`.
    ///    - maxItems: Defines the maximum amount of values in the `array`.
    ///    - uniqueItems: Specifies if all `array` elements need to be unique.
    public convenience init(
        description: String,
        const: (any CustomStringConvertible)? = nil,
        minItems: Int? = nil,
        maxItems: Int? = nil,
        uniqueItems: Bool? = nil
    ) {
        self.init(description: .init())
        self.schema = .init(
            type: T.schema.type,
            description: description,
            items: .init(
                type: T.Element.schema.type,
                const: const?.description
            ),
            minItems: minItems,
            maxItems: maxItems,
            uniqueItems: uniqueItems
        )
    }
}

extension _LLMFunctionParameterWrapper where T == [String] {
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
        description: String,
        pattern: String? = nil,
        const: (any CustomStringConvertible)? = nil,
        enumValues: [String]? = nil,
        minItems: Int? = nil,
        maxItems: Int? = nil,
        uniqueItems: Bool? = nil
    ) {
        self.init(description: .init())
        self.schema = .init(
            type: T.schema.type,
            description: description,
            items: .init(
                type: T.Element.schema.type,
                pattern: pattern,
                const: const?.description,
                enumValues: enumValues
            ),
            minItems: minItems,
            maxItems: maxItems,
            uniqueItems: uniqueItems
        )
    }
}

// swiftlint:enable discouraged_optional_boolean discouraged_optional_collection
