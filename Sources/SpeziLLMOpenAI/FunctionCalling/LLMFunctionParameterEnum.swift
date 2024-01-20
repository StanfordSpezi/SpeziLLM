//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation

/// Represents LLM function calling parameters in the shape of an `enum`.
///
/// Similar to ``LLMFunctionParameter``, the ``LLMFunctionParameterEnum`` represents `enum-based` ``LLMFunction/Parameter``s (`@Parameter`s) that are used within ``LLMFunction``s.
/// Similar to ``LLMFunctionParameter``, the protocol enforces the ``LLMFunctionParameter/schema`` property, which every ``LLMFunction/Parameter``
/// needs to implement so that OpenAI LLMs are able to structure the function call parameters.
///
/// For String-based `enum`s (so `RawValue` equals to `String`), the conformance to the ``LLMFunctionParameter`` protocol is done by SpeziLLM.
public protocol LLMFunctionParameterEnum: CaseIterable, RawRepresentable, LLMFunctionParameter {}


extension LLMFunctionParameterEnum where RawValue: StringProtocol {
    /// Convenience conformance of `enum`s to ``LLMFunctionParameter``, so developers can use enum-based types out of the box with ``LLMFunction``s.
    public static var schema: LLMFunctionParameterPropertySchema {
        .init(type: .string)    // String as we ensure `_LLMFunctionParameterWrapper where T: LLMFunctionParameterEnum, T.RawValue: StringProtocol `
    }
}
