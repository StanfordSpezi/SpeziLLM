//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziFoundation

// swiftlint:disable discouraged_optional_boolean

extension _LLMFunctionParameterWrapper where T: LLMFunctionParameterEnum, T.RawValue: StringProtocol {
    /// Declares an `enum`-based ``LLMFunction/Parameter`` defining all options of a text-based parameter of the ``LLMFunction``.
    ///
    /// - Parameters:
    ///    - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    ///    - const: Specifies the constant `String`-based value of a certain parameter.
    public convenience init<D: StringProtocol>(
        description: D,
        const: (any StringProtocol)? = nil
    ) {
        self.init(schema: .init(
            type: .string,
            description: String(description),
            const: const.map { String($0) },
            enumValues: T.allCases.map { String($0.rawValue) }
        ))
    }
}

extension _LLMFunctionParameterWrapper where T: AnyOptional, T.Wrapped: LLMFunctionParameterEnum, T.Wrapped.RawValue: StringProtocol {
    /// Declares an optional `enum`-based ``LLMFunction/Parameter`` defining all options of a text-based parameter of the ``LLMFunction``.
    ///
    /// - Parameters:
    ///    - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    ///    - const: Specifies the constant `String`-based value of a certain parameter.
    public convenience init<D: StringProtocol>(
        description: D,
        const: (any StringProtocol)? = nil
    ) {
        self.init(schema: .init(
            type: .string,
            description: String(description),
            const: const.map { String($0) },
            enumValues: T.Wrapped.allCases.map { String($0.rawValue) }
        ))
    }
}

extension _LLMFunctionParameterWrapper where T: AnyArray, T.Element: LLMFunctionParameterEnum, T.Element.RawValue: StringProtocol {
    /// Declares an `enum`-based ``LLMFunction/Parameter`` `array`. An individual `array` element defines all options of a text-based parameter of the ``LLMFunction``.
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
                type: .string,
                const: const.map { String($0) },
                enumValues: T.Element.allCases.map { String($0.rawValue) }
            ),
            minItems: minItems,
            maxItems: maxItems,
            uniqueItems: uniqueItems
        ))
    }
}

extension _LLMFunctionParameterWrapper where T: AnyOptional,
                                             T.Wrapped: AnyArray,
                                             T.Wrapped.Element: LLMFunctionParameterEnum,
                                             T.Wrapped.Element.RawValue: StringProtocol {
    /// Declares an optional `enum`-based ``LLMFunction/Parameter`` `array`. An individual `array` element defines all options of a text-based parameter of the ``LLMFunction``.
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
                type: .string,
                const: const.map { String($0) },
                enumValues: T.Wrapped.Element.allCases.map { String($0.rawValue) }
            ),
            minItems: minItems,
            maxItems: maxItems,
            uniqueItems: uniqueItems
        ))
    }
}

// swiftlint:enable discouraged_optional_boolean
