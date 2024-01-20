//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import OpenAI


extension Array: LLMFunctionParameter where Element: LLMFunctionParameterArrayItem {
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
