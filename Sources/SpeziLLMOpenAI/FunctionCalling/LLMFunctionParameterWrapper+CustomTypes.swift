//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziFoundation

// swiftlint:disable discouraged_optional_boolean

extension _LLMFunctionParameterWrapper where T: AnyArray, T.Element: LLMFunctionParameterArrayElement {
    /// Declares an ``LLMFunctionParameterArrayElement``-based (custom type) ``LLMFunction/Parameter`` `array`.
    ///
    /// - Parameters:
    ///    - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    ///    - minItems: Defines the minimum amount of values in the `array`.
    ///    - maxItems: Defines the maximum amount of values in the `array`.
    ///    - uniqueItems: Specifies if all `array` elements need to be unique.
    public convenience init<D: StringProtocol>(
        description: D,
        minItems: Int? = nil,
        maxItems: Int? = nil,
        uniqueItems: Bool? = nil
    ) {
        self.init(schema: .init(
            type: .array,
            description: String(description),
            items: .init(
                type: T.Element.itemSchema.type,
                properties: T.Element.itemSchema.properties,
                pattern: T.Element.itemSchema.pattern,
                const: T.Element.itemSchema.const,
                enumValues: T.Element.itemSchema.enumValues,
                multipleOf: T.Element.itemSchema.multipleOf,
                minimum: T.Element.itemSchema.minimum,
                maximum: T.Element.itemSchema.maximum
            ),
            minItems: minItems,
            maxItems: maxItems,
            uniqueItems: uniqueItems
        ))
    }
}

extension _LLMFunctionParameterWrapper where T: AnyOptional, T.Wrapped: AnyArray, T.Wrapped.Element: LLMFunctionParameterArrayElement {
    /// Declares an optional ``LLMFunctionParameterArrayElement``-based (custom type) ``LLMFunction/Parameter`` `array`.
    ///
    /// - Parameters:
    ///    - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    ///    - minItems: Defines the minimum amount of values in the `array`.
    ///    - maxItems: Defines the maximum amount of values in the `array`.
    ///    - uniqueItems: Specifies if all `array` elements need to be unique.
    public convenience init<D: StringProtocol>(
        description: D,
        minItems: Int? = nil,
        maxItems: Int? = nil,
        uniqueItems: Bool? = nil
    ) {
        self.init(schema: .init(
            type: .array,
            description: String(description),
            items: .init(
                type: T.Wrapped.Element.itemSchema.type,
                properties: T.Wrapped.Element.itemSchema.properties,
                pattern: T.Wrapped.Element.itemSchema.pattern,
                const: T.Wrapped.Element.itemSchema.const,
                enumValues: T.Wrapped.Element.itemSchema.enumValues,
                multipleOf: T.Wrapped.Element.itemSchema.multipleOf,
                minimum: T.Wrapped.Element.itemSchema.minimum,
                maximum: T.Wrapped.Element.itemSchema.maximum
            ),
            minItems: minItems,
            maxItems: maxItems,
            uniqueItems: uniqueItems
        ))
    }
}

// swiftlint:enable discouraged_optional_boolean
