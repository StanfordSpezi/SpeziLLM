//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable discouraged_optional_collection

extension _LLMFunctionParameterWrapper where T == Int {
    /// Creates an ``LLMFunction/Parameter`` of the type `Int` defining a integer parameter of the ``LLMFunction``.
    ///
    /// - Parameters:
    ///    - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    ///    - const: Specifies the constant `String`-based value of a certain parameter.
    ///    - multipleOf: Defines that the LLM parameter needs to be a multiple of the init argument.
    ///    - minimum: The minimum value of the parameter.
    ///    - maximum: The maximum value of the parameter.
    public convenience init(
        description: String,
        const: (any CustomStringConvertible)? = nil,
        multipleOf: Int? = nil,
        minimum: Int? = nil,
        maximum: Int? = nil
    ) {
        self.init(description: .init())
        let minimum: Double? = if let minimum { Double(minimum) } else { nil }
        let maximum: Double? = if let maximum { Double(maximum) } else { nil }
        self.schema = .init(
            type: T.schema.type,
            description: description,
            const: const?.description,
            multipleOf: multipleOf,
            minimum: minimum,
            maximum: maximum
        )
    }
}


extension _LLMFunctionParameterWrapper where T == Float {
    /// Creates an ``LLMFunction/Parameter`` of the type `Float` defining a floating-point parameter of the ``LLMFunction``.
    ///
    /// - Parameters:
    ///    - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    ///    - const: Specifies the constant `String`-based value of a certain parameter.
    ///    - minimum: The minimum value of the parameter.
    ///    - maximum: The maximum value of the parameter.
    public convenience init(
        description: String,
        const: (any CustomStringConvertible)? = nil,
        minimum: Float? = nil,
        maximum: Float? = nil
    ) {
        self.init(description: .init())
        let minimum: Double? = if let minimum { Double(minimum) } else { nil }
        let maximum: Double? = if let maximum { Double(maximum) } else { nil }
        self.schema = .init(
            type: T.schema.type,
            description: description,
            const: const?.description,
            minimum: minimum,
            maximum: maximum
        )
    }
}

extension _LLMFunctionParameterWrapper where T == Double {
    /// Creates an ``LLMFunction/Parameter`` of the type `Double` defining a floating-point parameter of the ``LLMFunction``.
    ///
    /// - Parameters:
    ///    - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    ///    - const: Specifies the constant `String`-based value of a certain parameter.
    ///    - minimum: The minimum value of the parameter.
    ///    - maximum: The maximum value of the parameter.
    public convenience init(
        description: String,
        const: (any CustomStringConvertible)? = nil,
        minimum: Double? = nil,
        maximum: Double? = nil
    ) {
        self.init(description: .init())
        self.schema = .init(
            type: T.schema.type,
            description: description,
            const: const?.description,
            minimum: minimum,
            maximum: maximum
        )
    }
}

extension _LLMFunctionParameterWrapper where T == Bool {
    /// Creates an ``LLMFunction/Parameter`` of the type `Bool` defining a binary parameter of the ``LLMFunction``.
    ///
    /// - Parameters:
    ///    - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    ///    - const: Specifies the constant `String`-based value of a certain parameter.
    public convenience init(description: String, const: (any CustomStringConvertible)? = nil) {
        self.init(description: .init())
        self.schema = .init(
            type: T.schema.type,
            description: description,
            const: const?.description
        )
    }
}

extension _LLMFunctionParameterWrapper where T == String {
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
        description: String,
        format: _LLMFunctionParameterWrapper.Format? = nil,
        pattern: String? = nil,
        const: (any CustomStringConvertible)? = nil,
        enumValues: [String]? = nil
    ) {
        self.init(description: .init())
        self.schema = .init(
            type: T.schema.type,
            description: description,
            format: format?.rawValue,
            pattern: pattern,
            const: const?.description,
            enumValues: enumValues
        )
    }
}

// swiftlint:enable discouraged_optional_collection
