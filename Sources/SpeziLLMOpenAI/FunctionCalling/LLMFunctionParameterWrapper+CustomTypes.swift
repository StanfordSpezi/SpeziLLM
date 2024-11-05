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
    public convenience init(
        description: some StringProtocol,
        minItems: Int? = nil,
        maxItems: Int? = nil,
        uniqueItems: Bool? = nil
    ) {
        do {
            let itemSchema = T.Element.itemSchema.value
            try self.init(schema: .init(unvalidatedValue: [
                "type": "array",
                "description": String(description),
                "items": [
                    "type": itemSchema["type"],
                    "properties": itemSchema["properties"],
                    "pattern": itemSchema["pattern"],
                    "const": itemSchema["const"],
                    "enum": itemSchema["enum"],
                    "multipleOf": itemSchema["multipleOf"],
                    "minimum": itemSchema["minimum"],
                    "maximum": itemSchema["maximum"]
                ].compactMapValues { $0 },
                "minItems": minItems as Any?,
                "maxItems": maxItems as Any?,
                "uniqueItems": uniqueItems as Any?
            ].compactMapValues { $0 }))
        } catch {
            logger.error("Couldn't create FunctionParameterWrapper+CustomType \(error)")
            self.init(description: "")
        }
    }
}

extension _LLMFunctionParameterWrapper where T: AnyOptional, T.Wrapped: AnyArray,
                                             T.Wrapped.Element: LLMFunctionParameterArrayElement {
    /// Declares an optional ``LLMFunctionParameterArrayElement``-based (custom type) ``LLMFunction/Parameter`` `array`.
    ///
    /// - Parameters:
    ///    - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    ///    - minItems: Defines the minimum amount of values in the `array`.
    ///    - maxItems: Defines the maximum amount of values in the `array`.
    ///    - uniqueItems: Specifies if all `array` elements need to be unique.
    convenience init(
        description: some StringProtocol,
        minItems: Int? = nil,
        maxItems: Int? = nil,
        uniqueItems: Bool? = nil
    ) {
        do {
            let itemSchema = T.Wrapped.Element.itemSchema.value
            try self.init(schema: .init(unvalidatedValue: [
                "type": "array",
                "description": String(description),
                "items": [
                    "type": itemSchema["type"],
                    "properties": itemSchema["properties"],
                    "pattern": itemSchema["pattern"],
                    "const": itemSchema["const"],
                    "enum": itemSchema["enum"],
                    "multipleOf": itemSchema["multipleOf"],
                    "minimum": itemSchema["minimum"],
                    "maximum": itemSchema["maximum"]
                ].compactMapValues { $0 },
                "minItems": minItems as Any?,
                "maxItems": maxItems as Any?,
                "uniqueItems": uniqueItems as Any?
            ].compactMapValues { $0 }))
        } catch {
            logger.error("Couldn't create LLMFunctionParameterWrapper+CustomTypes")
            self.init(description: "")
        }
    }
}

// swiftlint:enable discouraged_optional_boolean
