//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import OpenAI


extension Int: LLMFunctionParameter {
    /// Convenience conformance of `Int`s to ``LLMFunctionParameter``, so developers can use primitive types out of the box with ``LLMFunction``s.
    public static var schema: LLMFunctionParameterPropertySchema {
        .init(
            type: .integer
        )
    }
}

extension Float: LLMFunctionParameter {
    /// Convenience conformance of `Float`s to ``LLMFunctionParameter``, so developers can use primitive types out of the box with ``LLMFunction``s.
    public static var schema: LLMFunctionParameterPropertySchema {
        .init(
            type: .number
        )
    }
}

extension Double: LLMFunctionParameter {
    /// Convenience conformance of `Double`s to ``LLMFunctionParameter``, so developers can use primitive types out of the box with ``LLMFunction``s.
    public static var schema: LLMFunctionParameterPropertySchema {
        .init(
            type: .number
        )
    }
}

extension String: LLMFunctionParameter {
    /// Convenience conformance of `String`s to ``LLMFunctionParameter``, so developers can use primitive types out of the box with ``LLMFunction``s.
    public static var schema: LLMFunctionParameterPropertySchema {
        .init(
            type: .string
        )
    }
}

extension Bool: LLMFunctionParameter {
    /// Convenience conformance of `Bool`s to ``LLMFunctionParameter``, so developers can use primitive types out of the box with ``LLMFunction``s.
    public static var schema: LLMFunctionParameterPropertySchema {
        .init(
            type: .boolean
        )
    }
}

extension Array: LLMFunctionParameter where Element: LLMFunctionParameter {
    /// Convenience conformance of `Array`s to ``LLMFunctionParameter``, so developers can use array-based primitive types out of the box with ``LLMFunction``s.
    public static var schema: LLMFunctionParameterPropertySchema {
        .init(
            type: .array
        )
    }
}

extension Optional: LLMFunctionParameter where Wrapped: LLMFunctionParameter {
    /// Convenience conformance of `Optional`s to ``LLMFunctionParameter``, so developers can use wrapped primitive types out of the box with ``LLMFunction``s.
    public static var schema: LLMFunctionParameterPropertySchema {
        .init(
            type: Wrapped.schema.type
        )
    }
}
