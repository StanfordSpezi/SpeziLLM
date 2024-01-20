//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziFoundation

// swiftlint:disable discouraged_optional_boolean

extension _LLMFunctionParameterWrapper where T: LLMFunctionParameterEnum, T.RawValue: StringProtocol {
    /// Creates an `enum`-based ``LLMFunction/Parameter`` defining all options of a text-based parameter of the ``LLMFunction``.
    ///
    /// - Parameters:
    ///    - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    ///    - const: Specifies the constant `String`-based value of a certain parameter.
    public convenience init(
        description: any StringProtocol,
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
    /// Creates an optional `enum`-based ``LLMFunction/Parameter`` defining all options of a text-based parameter of the ``LLMFunction``.
    ///
    /// - Parameters:
    ///    - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    ///    - const: Specifies the constant `String`-based value of a certain parameter.
    public convenience init(
        description: String,
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
    /// Creates an `enum`-based ``LLMFunction/Parameter`` `array`. An individual `array` element defines all options of a text-based parameter of the ``LLMFunction``.
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
                type: .string,
                const: const.map { String($0) },
                enumValues: T.Element.allCases.map { String($0.rawValue) }
            ),
            minItems: minItems.map { Int($0) },
            maxItems: maxItems.map { Int($0) },
            uniqueItems: uniqueItems
        ))
    }
}

extension _LLMFunctionParameterWrapper where T: AnyOptional,
                                             T.Wrapped: AnyArray,
                                             T.Wrapped.Element: LLMFunctionParameterEnum,
                                             T.Wrapped.Element.RawValue: StringProtocol {
    /// Creates an optional `enum`-based ``LLMFunction/Parameter`` `array`. An individual `array` element defines all options of a text-based parameter of the ``LLMFunction``.
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
                type: .string,
                const: const.map { String($0) },
                enumValues: T.Wrapped.Element.allCases.map { String($0.rawValue) }
            ),
            minItems: minItems.map { Int($0) },
            maxItems: maxItems.map { Int($0) },
            uniqueItems: uniqueItems
        ))
    }
}

// swiftlint:enable discouraged_optional_boolean
