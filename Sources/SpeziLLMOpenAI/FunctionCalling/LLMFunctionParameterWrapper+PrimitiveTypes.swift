//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable discouraged_optional_collection

extension _LLMFunctionParameterWrapper where T: BinaryInteger {
    /// Creates an ``LLMFunction/Parameter`` of the type `Int` defining a integer parameter of the ``LLMFunction``.
    ///
    /// - Parameters:
    ///    - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    ///    - const: Specifies the constant `String`-based value of a certain parameter.
    ///    - multipleOf: Defines that the LLM parameter needs to be a multiple of the init argument.
    ///    - minimum: The minimum value of the parameter.
    ///    - maximum: The maximum value of the parameter.
    public convenience init(
        description: any StringProtocol,
        const: (any StringProtocol)? = nil,
        multipleOf: (any BinaryInteger)? = nil,
        minimum: T? = nil,
        maximum: T? = nil
    ) {
        self.init(schema: .init(
            type: .integer,
            description: String(description),
            const: const.map { String($0) },
            multipleOf: multipleOf.map { Int($0) },
            minimum: minimum.map { Double($0) },
            maximum: maximum.map { Double($0) }
        ))
    }
}


extension _LLMFunctionParameterWrapper where T: BinaryFloatingPoint {
    /// Creates an ``LLMFunction/Parameter`` of the type `Float` or `Double` (`BinaryFloatingPoint`) defining a floating-point parameter of the ``LLMFunction``.
    ///
    /// - Parameters:
    ///    - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    ///    - const: Specifies the constant `String`-based value of a certain parameter.
    ///    - minimum: The minimum value of the parameter.
    ///    - maximum: The maximum value of the parameter.
    public convenience init(
        description: any StringProtocol,
        const: (any StringProtocol)? = nil,
        minimum: T? = nil,
        maximum: T? = nil
    ) {
        self.init(schema: .init(
            type: .number,
            description: String(description),
            const: const.map { String($0) },
            minimum: minimum.map { Double($0) },
            maximum: maximum.map { Double($0) }
        ))
    }
}

extension _LLMFunctionParameterWrapper where T == Bool {
    /// Creates an ``LLMFunction/Parameter`` of the type `Bool` defining a binary parameter of the ``LLMFunction``.
    ///
    /// - Parameters:
    ///    - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    ///    - const: Specifies the constant `String`-based value of a certain parameter.
    public convenience init(description: any StringProtocol, const: (any StringProtocol)? = nil) {
        self.init(schema: .init(
            type: .boolean,
            description: String(description),
            const: const.map { String($0) }
        ))
    }
}

extension _LLMFunctionParameterWrapper where T: StringProtocol {
    // TODO
    // https://json-schema.org/draft-06/json-schema-validation
    // 
    // "pattern": "\d\d\d\d-\d\d-\d\d", Regex    https://json-schema.org/draft-06/json-schema-validation#rfc.section.6.8
    // "format": "date", Type     https://json-schema.org/draft-06/json-schema-validation#rfc.section.8
    // "const": The value of this keyword MAY be of any type, including null. An instance validates successfully against this keyword if its value is equal to the value of the keyword.   https://json-schema.org/draft-06/json-schema-validation#rfc.section.6.24
    
    
    /// Creates an ``LLMFunction/Parameter`` of the type `String` defining a text-based parameter of the ``LLMFunction``.
    ///
    /// - Parameters:
    ///    - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    ///    - format: Defines a required format of the parameter, allowing interoperable semantic validation of the value.
    ///    - pattern: A Regular Expression that the parameter needs to conform to.
    ///    - const: Specifies the constant `String`-based value of a certain parameter.
    ///    - enumValues: Defines all cases of the `String` parameter.
    public convenience init(
        description: any StringProtocol,
        format: _LLMFunctionParameterWrapper.Format? = nil,
        pattern: (any StringProtocol)? = nil,
        const: (any StringProtocol)? = nil,
        enumValues: [any StringProtocol]? = nil
    ) {
        self.init(schema: .init(
            type: .string,
            description: String(description),
            format: format?.rawValue,
            pattern: pattern.map { String($0) },
            const: const.map { String($0) },
            enumValues: enumValues.map { $0.map { String($0) } }
        ))
    }
}

// swiftlint:enable discouraged_optional_collection
