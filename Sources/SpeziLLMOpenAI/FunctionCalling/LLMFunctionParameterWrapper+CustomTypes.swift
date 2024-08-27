//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import OpenAI
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
            // FIXME: How can this be simplified?
            var addProp: [String: any Sendable] = [
                "type": "array",
                "description": String(description)
            ]
            var itemNonOpt: [String: any Sendable] = [
                "type": T.Element.itemSchema.type.rawValue
            ]
            if let properties = T.Element.itemSchema.properties?.mapValues({ $0.toDict() }) {
                itemNonOpt["properties"] = properties
            }
            if let pattern = T.Element.itemSchema.pattern {
                itemNonOpt["pattern"] = pattern
            }
            if let const = T.Element.itemSchema.const {
                itemNonOpt["const"] = const
            }
            if let `enum` = T.Element.itemSchema.enum {
                itemNonOpt["enum"] = `enum`
            }
            if let multipleOf = T.Element.itemSchema.multipleOf {
                itemNonOpt["multipleOf"] = multipleOf
            }
            if let minimum = T.Element.itemSchema.minimum {
                itemNonOpt["minimum"] = minimum
            }
            if let maximum = T.Element.itemSchema.maximum {
                itemNonOpt["maximum"] = maximum
            }
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
            // FIXME: handle error correctly
            fatalError("Couldn't create FunctionParameterWrapper+CustomType \(error)")
        }
    }
}

// FIXME: This should probably be made redundant as part of bigger simplification for initialising the wrappers
extension ChatQuery.ChatCompletionToolParam.FunctionDefinition.FunctionParameters.Property {
    public func toDict() -> [String: any Sendable] {
        var res: [String: any Sendable] = [
            "type": Self.JSONType.string.rawValue
        ]
        if let description {
            res["description"] = description
        }
        if let format {
            res["format"] = format
        }
        if let items {
            res["items"] = items.toDict()
        }
        if let required {
            res["required"] = required
        }
        if let pattern {
            res["pattern"] = pattern
        }
        if let const {
            res["const"] = const
        }
        if let `enum` {
            res["enum"] = `enum`
        }
        if let multipleOf {
            res["multipleOf"] = multipleOf
        }
        if let minimum {
            res["minimum"] = minimum
        }
        if let maximum {
            res["maximum"] = maximum
        }
        if let minItems {
            res["minItems"] = minItems
        }
        if let maxItems {
            res["maxItems"] = maxItems
        }
        if let uniqueItems {
            res["uniqueItems"] = uniqueItems
        }
        return res
    }
}

// FIXME: This should probably be made redundant as part of bigger simplification for initialising the wrappers
extension ChatQuery.ChatCompletionToolParam.FunctionDefinition.FunctionParameters.Property.Items {
    public func toDict() -> [String: any Sendable] {
        var res: [String: any Sendable] = [
            "type": Self.JSONType.string.rawValue
        ]
        if let properties = properties?.mapValues({ $0.toDict() }) {
            res["properties"] = properties
        }
        if let pattern {
            res["pattern"] = pattern
        }
        if let const {
            res["const"] = const
        }
        if let `enum` {
            res["enum"] = `enum`
        }
        if let multipleOf {
            res["multipleOf"] = multipleOf
        }
        if let minimum {
            res["minimum"] = minimum
        }
        if let maximum {
            res["maximum"] = maximum
        }
        if let minItems {
            res["minItems"] = minItems
        }
        if let maxItems {
            res["maxItems"] = maxItems
        }
        if let uniqueItems {
            res["uniqueItems"] = uniqueItems
        }
        return res
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
            // FIXME: How can this be simplified?
            var addProp: [String: any Sendable] = [
                "type": "array",
                "description": String(description)
            ]
            var itemNonOpt: [String: any Sendable] = [
                "type": T.Wrapped.Element.itemSchema.type.rawValue
            ]
            if let properties = T.Wrapped.Element.itemSchema.properties?.mapValues({ $0.toDict() }) {
                itemNonOpt["properties"] = properties
            }
            if let pattern = T.Wrapped.Element.itemSchema.pattern {
                itemNonOpt["pattern"] = pattern
            }
            if let const = T.Wrapped.Element.itemSchema.const {
                itemNonOpt["const"] = const
            }
            if let `enum` = T.Wrapped.Element.itemSchema.enum {
                itemNonOpt["enum"] = `enum`
            }
            if let multipleOf = T.Wrapped.Element.itemSchema.multipleOf {
                itemNonOpt["multipleOf"] = multipleOf
            }
            if let minimum = T.Wrapped.Element.itemSchema.minimum {
                itemNonOpt["minimum"] = minimum
            }
            if let maximum = T.Wrapped.Element.itemSchema.maximum {
                itemNonOpt["maximum"] = maximum
            }
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
            // FIXME: handle error correctly
            fatalError("Couldn't create LLMFunctionParameterWrapper+CustomTypes")
        }
    }
}

// swiftlint:enable discouraged_optional_boolean
