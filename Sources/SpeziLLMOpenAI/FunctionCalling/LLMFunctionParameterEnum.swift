//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation

public protocol LLMFunctionParameterEnum: CaseIterable, RawRepresentable, LLMFunctionParameter {}


extension LLMFunctionParameterEnum {
    /// Convenience conformance of `enum`s to ``LLMFunctionParameter``, so developers can use enum-based types out of the box with ``LLMFunction``s.
    public static var schema: LLMFunctionParameterPropertySchema {
        .init(type: .string)    // String as we ensure `_LLMFunctionParameterWrapper where T: LLMFunctionParameterEnum, T.RawValue == String`
    }
}

