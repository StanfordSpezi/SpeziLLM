//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziChat
import SpeziLLM
import SpeziLLMOpenAI

public struct LLMOpenAIRealtimeSchema: LLMSchema, Sendable {
    public typealias Platform = LLMOpenAIRealtimePlatform
    
    
    /// Default values of ``LLMOpenAISchema``.
    public enum Defaults {
        /// Empty default of passed function calls (`_LLMFunctionCollection`).
        /// Reason: Cannot use internal init of `_LLMFunctionCollection` as default parameter within public ``LLMOpenAISchema/init(parameters:modelParameters:injectIntoContext:_:)``.
        nonisolated(unsafe) public static let emptyLLMFunctions: _LLMFunctionCollection = .init(functions: [])
    }

    
    let functions: [String: any LLMFunction]
    public var injectIntoContext: Bool
    
    public init(
        injectIntoContext: Bool = false,
        @LLMFunctionBuilder _ functionsCollection: @escaping () -> _LLMFunctionCollection = { Defaults.emptyLLMFunctions }
    ) {
        self.injectIntoContext = injectIntoContext
        self.functions = functionsCollection().functions
    }
}
