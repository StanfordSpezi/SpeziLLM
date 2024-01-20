//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


extension Optional: LLMFunctionParameterArrayItem where Wrapped: LLMFunctionParameter {
    /// Convenience conformance of `Optional`s to ``LLMFunctionParameterArrayItem``, so developers can use wrapped primitive types out of the box with ``LLMFunction``s.
    public static var itemSchema: LLMFunctionParameterItemSchema {
        .init(
            type: Self.schema.type
        )
    }
}
