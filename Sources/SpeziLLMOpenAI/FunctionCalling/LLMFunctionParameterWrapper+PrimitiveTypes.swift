//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable discouraged_optional_collection

extension _LLMFunctionParameterWrapper where T: BinaryInteger {
    /// Declares an ``LLMFunction/Parameter`` of the type `Int` defining a integer parameter of the ``LLMFunction``.
    ///
    /// - Parameters:
    ///    - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    ///    - const: Specifies the constant `String`-based value of a certain parameter.
    ///    - multipleOf: Defines that the LLM parameter needs to be a multiple of the init argument.
    ///    - minimum: The minimum value of the parameter.
    ///    - maximum: The maximum value of the parameter.
    convenience init(
        description: some StringProtocol,
        const: (any StringProtocol)? = nil,
        multipleOf: Int? = nil,
        minimum: T? = nil,
        maximum: T? = nil
    ) {
        do {
            try self.init(schema: .init(unvalidatedValue: [
                    "type": "integer",
                    "description": String(description),
                    "const": const.map { String($0) } as Any?,
                    "multipleOf": multipleOf as Any?,
                    "minimum": minimum.map { Double($0) } as Any?,
                    "maximum": maximum.map { Double($0) } as Any?
            ].compactMapValues { $0 }))
        } catch {
            preconditionFailure("SpeziLLMOpenAI: Failed to create validated function call schema definition of `LLMFunction/Parameter`: \(error)")
        }
    }
}

extension _LLMFunctionParameterWrapper where T: BinaryFloatingPoint {
    /// Declares an ``LLMFunction/Parameter`` of the type `Float` or `Double` (`BinaryFloatingPoint`) defining a
    /// floating-point parameter of the ``LLMFunction``.
    ///
    /// - Parameters:
    ///    - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    ///    - const: Specifies the constant `String`-based value of a certain parameter.
    ///    - minimum: The minimum value of the parameter.
    ///    - maximum: The maximum value of the parameter.
    public convenience init(
        description: some StringProtocol,
        const: (any StringProtocol)? = nil,
        minimum: T? = nil,
        maximum: T? = nil
    ) {
        do {
            try self.init(schema: .init(unvalidatedValue: [
                "type": "number",
                "description": String(description),
                "const": const.map { String($0) } as Any?,
                "minimum": minimum.map { Double($0) } as Any?,
                "maximum": maximum.map { Double($0) } as Any?
            ].compactMapValues { $0 }))
        } catch {
            preconditionFailure("SpeziLLMOpenAI: Failed to create validated function call schema definition of `LLMFunction/Parameter`: \(error)")
        }
    }
}

extension _LLMFunctionParameterWrapper where T == Bool {
    /// Declares an ``LLMFunction/Parameter`` of the type `Bool` defining a binary parameter of the ``LLMFunction``.
    ///
    /// - Parameters:
    ///    - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    ///    - const: Specifies the constant `String`-based value of a certain parameter.
    public convenience init(
        description: some StringProtocol,
        const: (any StringProtocol)? = nil
    ) {
        do {
            try self.init(schema: .init(unvalidatedValue:
            [
                "type": "boolean",
                "description": String(description),
                "const": const.map { String($0) } as Any?
            ].compactMapValues { $0 }))
        } catch {
            preconditionFailure("SpeziLLMOpenAI: Failed to create validated function call schema definition of `LLMFunction/Parameter`: \(error)")
        }
    }
}

extension _LLMFunctionParameterWrapper where T: StringProtocol {
    /// Declares an ``LLMFunction/Parameter`` of the type `String` defining a text-based parameter of the
    /// ``LLMFunction``.
    ///
    /// - Parameters:
    ///    - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    ///    - format: Defines a required format of the parameter, allowing interoperable semantic validation of the
    /// value.
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
            try self.init(schema: .init(unvalidatedValue: [
                "type": "string",
                "description": String(description),
                "format": format?.rawValue as Any?,
                "pattern": pattern.map { String($0) } as Any?,
                "const": const.map { String($0) } as Any?,
                "enum": `enum`.map { $0.map { String($0) } } as Any?
            ].compactMapValues { $0 }))
        } catch {
            preconditionFailure("SpeziLLMOpenAI: Failed to create validated function call schema definition of `LLMFunction/Parameter`: \(error)")
        }
    }
}

// swiftlint:enable discouraged_optional_collection
