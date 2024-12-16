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
    public convenience init(
        description: some StringProtocol,
        const: (any StringProtocol)? = nil,
        multipleOf: Int? = nil,
        minimum: T.Wrapped? = nil,
        maximum: T.Wrapped? = nil
    ) {
        do {
            // FIXME: How can this be simplified?
            var addProp: [String: any Sendable] = [
                "type": "integer",
                "description": String(description)
            ]
            if let const {
                addProp["const"] = String(const)
            }
            if let multipleOf {
                addProp["multipleOf "] = multipleOf
            }
            if let minimum {
                addProp["minimum"] = Double(minimum)
            }
            if let maximum {
                addProp["maximum"] = Double(maximum)
            }
            try self.init(schema: .init(additionalProperties: .init(unvalidatedValue: addProp)))
        } catch {
            // FIXME: handle error correctly
            fatalError("LLMFunctionparaemter+OptionalType")
        }
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
    public convenience init(
        description: some StringProtocol,
        const: (any StringProtocol)? = nil,
        minimum: T.Wrapped? = nil,
        maximum: T.Wrapped? = nil
    ) {
        do {
            // FIXME: How can this be simplified?
            var addProp: [String: any Sendable] = [
                "type": "number",
                "description": String(description)
            ]
            if let const {
                addProp["const"] = String(const)
            }
            if let minimum {
                addProp["minimum"] = Double(minimum)
            }
            if let maximum {
                addProp["maximum"] = Double(maximum)
            }
            try self.init(schema: .init(additionalProperties: .init(unvalidatedValue: addProp)))
        } catch {
            // FIXME: handle error correctly
            fatalError("LLMFunctionParameterWrapper+OptionalType")
        }
    }
}

extension _LLMFunctionParameterWrapper where T: AnyOptional, T.Wrapped == Bool {
    /// Declares an ``LLMFunction/Parameter`` of the type `Bool?` defining a binary parameter of the ``LLMFunction``.
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
                "type": "boolean",
                "description": String(description)
            ]
            if let const {
                addProp["const"] = String(const)
            }
            try self.init(schema: .init(additionalProperties: .init(unvalidatedValue: addProp)))
        } catch {
            // FIXME: handle error correctly
            fatalError("LLMFunctionalParameterWrapper+OptionalTypes")
        }
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
    public convenience init(
        description: some StringProtocol,
        format: _LLMFunctionParameterWrapper.Format? = nil,
        pattern: (any StringProtocol)? = nil,
        const: (any StringProtocol)? = nil,
        enum: [any StringProtocol]? = nil
    ) {
        do {
            // FIXME: How can this be simplified?
            var addProp: [String: any Sendable] = [
                "type": "string",
                "description": String(description)
            ]
            if let format {
                addProp["format"] = format.rawValue
            }
            if let pattern {
                addProp["pattern"] = String(pattern)
            }
            if let const {
                addProp["const"] = String(const)
            }
            if let `enum` {
                addProp["enum"] = `enum`.map { $0.map { String($0) } }
            }
            try self.init(schema: .init(additionalProperties: .init(unvalidatedValue: addProp)))

        } catch {
            // FIXME: handle error correctly
            fatalError("LLMFunctionParameterWrapper+OptionalTypes")
        }
    }
}

extension _LLMFunctionParameterWrapper where T: AnyOptional, T.Wrapped: AnyArray,
    T.Wrapped.Element: BinaryInteger {
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
    public convenience init(
        description: some StringProtocol,
        const: (any StringProtocol)? = nil,
        multipleOf: Int? = nil,
        minimum: T.Wrapped.Element? = nil,
        maximum: T.Wrapped.Element? = nil,
        minItems: Int? = nil,
        maxItems: Int? = nil,
        uniqueItems _: Bool? = nil
    ) {
        do {
            // FIXME: How can this be simplified?
            var addProp: [String: any Sendable] = [
                "type": "array",
                "description": String(description)
            ]
            var itemNonOpt: [String: any Sendable] = [
                "type": "integer"
            ]
            if let const {
                itemNonOpt["const"] = String(const)
            }
            if let multipleOf {
                itemNonOpt["multipleOf"] = String(multipleOf)
            }
            if let minimum {
                itemNonOpt["minimum"] = Double(minimum)
            }
            if let maximum {
                itemNonOpt["maximum"] = Double(maximum)
            }
            if itemNonOpt.count > 1 {
                addProp["items"] = itemNonOpt
            }
            if let minItems {
                addProp["minItems"] = minItems
            }
            if let maxItems {
                addProp["maxItems"] = maxItems
            }
            try self.init(schema: .init(additionalProperties: .init(unvalidatedValue: addProp)))
        } catch {
            // FIXME: handle error correctly
            fatalError("LLMFunctionPropertyWrapper+OptionalType")
        }
    }
}

extension _LLMFunctionParameterWrapper where T: AnyOptional, T.Wrapped: AnyArray,
    T.Wrapped.Element: BinaryFloatingPoint {
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
    public convenience init(
        description: some StringProtocol,
        const: (any StringProtocol)? = nil,
        minimum: T.Wrapped.Element? = nil,
        maximum: T.Wrapped.Element? = nil,
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
                "type": "number"
            ]
            if let const {
                itemNonOpt["const"] = String(const)
            }
            if let minimum {
                itemNonOpt["minimum"] = Double(minimum)
            }
            if let maximum {
                itemNonOpt["maximum"] = Double(maximum)
            }
            if itemNonOpt.count > 1 {
                addProp["items"] = itemNonOpt
            }
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
            fatalError("LLMFunctionParameterWrapper+OptionalTypes")
        }
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
                "type": "boolean"
            ]
            if let const {
                itemNonOpt["const"] = String(const)
            }
            if itemNonOpt.count > 1 {
                addProp["items"] = itemNonOpt
            }
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
            fatalError("LLMFunctionParameterWrapper+OptionalTypes.swift")
        }
    }
}

extension _LLMFunctionParameterWrapper where T: AnyOptional, T.Wrapped: AnyArray,
    T.Wrapped.Element: StringProtocol {
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
    public convenience init(
        description: some StringProtocol,
        pattern: (any StringProtocol)? = nil,
        const: (any StringProtocol)? = nil,
        enum: [any StringProtocol]? = nil,
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
            if let pattern {
                itemNonOpt["pattern"] = String(pattern)
            }
            if let const {
                itemNonOpt["const"] = String(const)
            }
            if let `enum` {
                itemNonOpt["enum"] = `enum`.map { $0.map { String($0) } }
            }
            if itemNonOpt.count > 1 {
                addProp["items"] = itemNonOpt
            }
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
            fatalError("LLMFunctionParameterWrapper+OptionalType")
        }
    }
}

// swiftlint:enable discouraged_optional_boolean discouraged_optional_collection
