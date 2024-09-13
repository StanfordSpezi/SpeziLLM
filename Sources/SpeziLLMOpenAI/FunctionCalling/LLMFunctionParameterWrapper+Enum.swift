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
    public convenience init(
        description: some StringProtocol,
        const: (any StringProtocol)? = nil
    ) {
        do {
            // FIXME: How can this be simplified?
            var addProp: [String: any Sendable] = [
                "type": "string",
                "description": String(description)
            ]
            if let const {
                addProp["const"] = String(const)
            }
            addProp["enum"] = T.allCases.map { String($0.rawValue) }
            try self.init(schema: .init(additionalProperties: .init(unvalidatedValue: addProp)))
        } catch {
            logger.error("SpeziLLMOpenAI - initialization error - LLMFunctionParameterWrapper+Enum")
            self.init(description: "")
        }
    }
}

extension _LLMFunctionParameterWrapper where T: AnyOptional, T.Wrapped: LLMFunctionParameterEnum,
    T.Wrapped.RawValue: StringProtocol {
    /// Declares an optional `enum`-based ``LLMFunction/Parameter`` defining all options of a text-based parameter of the ``LLMFunction``.
    ///
    /// - Parameters:
    ///    - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    ///    - const: Specifies the constant `String`-based value of a certain parameter.
    public convenience init(
        description: some StringProtocol,
        const: (any StringProtocol)? = nil
    ) {
        do {
            // FIXME: How can this be simplified?
            var addProp: [String: any Sendable] = [
                "type": "string",
                "description": String(description)
            ]
            if let const {
                addProp["const"] = String(const)
            }
            addProp["enum"] = T.Wrapped.allCases.map { String($0.rawValue) }
            try self.init(schema: .init(additionalProperties: .init(unvalidatedValue: addProp)))
        } catch {
            logger.error("SpeziLLMOpenAI - initialization error - LLMFunctionParameterWrapper+Enum")
            self.init(description: "")
        }
    }
}

extension _LLMFunctionParameterWrapper where T: AnyArray, T.Element: LLMFunctionParameterEnum,
    T.Element.RawValue: StringProtocol {
    /// Declares an `enum`-based ``LLMFunction/Parameter`` `array`. An individual `array` element defines all options of a text-based parameter of the ``LLMFunction``.
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
            // FIXME: How can this be simplified?
            var addProp: [String: any Sendable] = [
                "type": "array",
                "description": String(description)
            ]
            var itemNonOpt: [String: any Sendable] = [
                "type": "string"
            ]
            if let const {
                itemNonOpt["const"] = String(const)
            }
            itemNonOpt["enum"] = T.Element.allCases.map { String($0.rawValue) }
            addProp["items"] = itemNonOpt
            if let minItems {
                addProp["minItems"] = minItems
            }
            if let maxItems {
                addProp["maxItems"] = maxItems
            }
            if let uniqueItems {
                addProp["uniqueItems"] = uniqueItems
            }
            try self.init(schema: .init(additionalProperties: .init(unvalidatedValue: addProp)))
        } catch {
            logger.error("SpeziLLMOpenAI - initialization error - LLMFunctionParameterWrapper+Enum")
            self.init(description: "")
        }
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
    public convenience init(
        description: some StringProtocol,
        const: (any StringProtocol)? = nil,
        minItems: Int? = nil,
        maxItems: Int? = nil,
        uniqueItems: Bool? = nil
    ) {
        do {
            // FIXME: How can this be simplified?
            var addProp: [String: any Sendable] = [
                "type": "array",
                "description": String(description)
            ]
            var itemNonOpt: [String: any Sendable] = [
                "type": "string"
            ]
            if let const {
                itemNonOpt["const"] = String(const)
            }
            itemNonOpt["enum"] = T.Wrapped.Element.allCases.map { String($0.rawValue) }
            addProp["items"] = itemNonOpt
            if let minItems {
                addProp["minItems"] = minItems
            }
            if let maxItems {
                addProp["maxItems"] = maxItems
            }
            if let uniqueItems {
                addProp["uniqueItems"] = uniqueItems
            }
            try self.init(schema: .init(additionalProperties: .init(unvalidatedValue: addProp)))
        } catch {
            logger.error("SpeziLLMOpenAI - initialization error - LLMFunctionParameterWrapper+Enum")
            self.init(description: "")
        }
    }
}

// swiftlint:enable discouraged_optional_boolean
