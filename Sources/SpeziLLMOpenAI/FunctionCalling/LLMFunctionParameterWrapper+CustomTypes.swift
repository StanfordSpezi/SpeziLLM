//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziFoundation


// TODO: This doesn't work yet as the properties are tricky..
// TODO: Do we need more parameters here? No?
extension _LLMFunctionParameterWrapper where T: AnyArray, T.Element: LLMFunctionParameter {
    /// Creates an `LLMFunctionParameter`-based (custom type) ``LLMFunction/Parameter`` `array`.
    ///
    /// - Parameters:
    ///    - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    ///    - minItems: Defines the minimum amount of values in the `array`.
    ///    - maxItems: Defines the maximum amount of values in the `array`.
    ///    - uniqueItems: Specifies if all `array` elements need to be unique.
    public convenience init(
        description: String,
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
                // TODO: How should that work? Separate LLMFunctionParameter type for Array that uses a different type?
                //properties: T.Element.schema.properties,
                
                pattern: T.Element.schema.pattern,
                const: T.Element.schema.const,
                enumValues: T.Element.schema.enumValues,
                multipleOf: T.Element.schema.multipleOf,
                minimum: T.Element.schema.minimum,
                maximum: T.Element.schema.maximum
            ),
            minItems: minItems,
            maxItems: maxItems,
            uniqueItems: uniqueItems
        )
    }
}

extension _LLMFunctionParameterWrapper where T: AnyOptional, T.Wrapped: AnyArray, T.Wrapped.Element: LLMFunctionParameter {
    /// Creates an optional `LLMFunctionParameter`-based (custom type) ``LLMFunction/Parameter`` `array`.
    ///
    /// - Parameters:
    ///    - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    ///    - minItems: Defines the minimum amount of values in the `array`.
    ///    - maxItems: Defines the maximum amount of values in the `array`.
    ///    - uniqueItems: Specifies if all `array` elements need to be unique.
    public convenience init(
        description: String,
        minItems: Int? = nil,
        maxItems: Int? = nil,
        uniqueItems: Bool? = nil
    ) {
        self.init(description: .init())
        self.schema = .init(
            type: T.schema.type,
            description: description,
            items: .init(
                type: T.Wrapped.Element.schema.type,
                // TODO: How should that work? Separate LLMFunctionParameter type for Array that uses a different type?
                //properties: T.Wrapped.Element.schema.properties,
                
                pattern: T.Wrapped.Element.schema.pattern,
                const: T.Wrapped.Element.schema.const,
                enumValues: T.Wrapped.Element.schema.enumValues,
                multipleOf: T.Wrapped.Element.schema.multipleOf,
                minimum: T.Wrapped.Element.schema.minimum,
                maximum: T.Wrapped.Element.schema.maximum
            ),
            minItems: minItems,
            maxItems: maxItems,
            uniqueItems: uniqueItems
        )
    }
}
