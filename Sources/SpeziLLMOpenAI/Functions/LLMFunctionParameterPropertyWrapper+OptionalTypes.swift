//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable discouraged_optional_boolean discouraged_optional_collection

extension _LLMFunctionParameterWrapper where T == Int? {
    public convenience init(
        description: String,
        format: String? = nil,
        const: String? = nil,
        multipleOf: Int? = nil,
        minimum: Double? = nil,
        maximum: Double? = nil
    ) {
        self.init(description: .init())
        self.schema = .init(
            type: .integer,
            description: description,
            format: format,
            const: const,
            multipleOf: multipleOf,
            minimum: minimum,
            maximum: maximum
        )
    }
}

extension _LLMFunctionParameterWrapper where T == Float? {
    public convenience init(description: String, format: String? = nil, const: String? = nil, minimum: Double? = nil, maximum: Double? = nil) {
        self.init(description: .init())
        self.schema = .init(
            type: .number,
            description: description,
            format: format,
            const: const,
            minimum: minimum,
            maximum: maximum
        )
    }
}

extension _LLMFunctionParameterWrapper where T == Double? {
    public convenience init(description: String, format: String? = nil, const: String? = nil, minimum: Double? = nil, maximum: Double? = nil) {
        self.init(description: .init())
        self.schema = .init(
            type: .number,
            description: description,
            format: format,
            const: const,
            minimum: minimum,
            maximum: maximum
        )
    }
}

extension _LLMFunctionParameterWrapper where T == Bool? {
    public convenience init(description: String, format: String? = nil, const: String? = nil) {
        self.init(description: .init())
        self.schema = .init(
            type: .boolean,
            description: description,
            format: format,
            const: const
        )
    }
}

extension _LLMFunctionParameterWrapper where T == String? {
    public convenience init(description: String, format: String? = nil, pattern: String? = nil, const: String? = nil, enumValues: [String]? = nil) {
        self.init(description: .init())
        self.schema = .init(
            type: .string,
            description: description,
            format: format,
            pattern: pattern,
            const: const,
            enumValues: enumValues
        )
    }
}

extension _LLMFunctionParameterWrapper where T == [Int]? {
    public convenience init(
        description: String,
        const: String? = nil,
        multipleOf: Int? = nil,
        minimum: Double? = nil,
        maximum: Double? = nil,
        minItems: Int? = nil,
        maxItems: Int? = nil,
        uniqueItems: Bool? = nil
    ) {
        self.init(description: .init())
        self.schema = .init(
            type: .array,
            description: description,
            items: .init(
                type: .integer,
                const: const,
                multipleOf: multipleOf,
                minimum: minimum,
                maximum: maximum
            ),
            minItems: minItems,
            maxItems: maxItems,
            uniqueItems: uniqueItems
        )
    }
}

extension _LLMFunctionParameterWrapper where T == [Float]? {
    public convenience init(
        description: String,
        const: String? = nil,
        minimum: Double? = nil,
        maximum: Double? = nil,
        minItems: Int? = nil,
        maxItems: Int? = nil,
        uniqueItems: Bool? = nil
    ) {
        self.init(description: .init())
        self.schema = .init(
            type: .array,
            description: description,
            items: .init(
                type: .number,
                const: const,
                minimum: minimum,
                maximum: maximum
            ),
            minItems: minItems,
            maxItems: maxItems,
            uniqueItems: uniqueItems
        )
    }
}

extension _LLMFunctionParameterWrapper where T == [Double]? {
    public convenience init(
        description: String,
        const: String? = nil,
        minimum: Double? = nil,
        maximum: Double? = nil,
        minItems: Int? = nil,
        maxItems: Int? = nil,
        uniqueItems: Bool? = nil
    ) {
        self.init(description: .init())
        self.schema = .init(
            type: .array,
            description: description,
            items: .init(
                type: .number,
                const: const,
                minimum: minimum,
                maximum: maximum
            ),
            minItems: minItems,
            maxItems: maxItems,
            uniqueItems: uniqueItems
        )
    }
}

extension _LLMFunctionParameterWrapper where T == [Bool]? {
    public convenience init(description: String, const: String? = nil, minItems: Int? = nil, maxItems: Int? = nil, uniqueItems: Bool? = nil) {
        self.init(description: .init())
        self.schema = .init(
            type: .array,
            description: description,
            items: .init(
                type: .boolean,
                const: const
            ),
            minItems: minItems,
            maxItems: maxItems,
            uniqueItems: uniqueItems
        )
    }
}

extension _LLMFunctionParameterWrapper where T == [String]? {
    public convenience init(
        description: String,
        pattern: String? = nil,
        const: String? = nil,
        enumValues: [String]? = nil,
        minItems: Int? = nil,
        maxItems: Int? = nil,
        uniqueItems: Bool? = nil
    ) {
        self.init(description: .init())
        self.schema = .init(
            type: .array,
            description: description,
            items: .init(
                type: .string,
                pattern: pattern,
                const: const,
                enumValues: enumValues
            ),
            minItems: minItems,
            maxItems: maxItems,
            uniqueItems: uniqueItems
        )
    }
}

// swiftlint:enable discouraged_optional_boolean discouraged_optional_collection
