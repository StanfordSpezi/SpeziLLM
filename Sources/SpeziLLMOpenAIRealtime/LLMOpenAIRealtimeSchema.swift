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
    
    
    /// Default values of ``LLMOpenAIRealtimeSchema``.
    public enum Defaults {
        /// Empty default of passed function calls (`_LLMFunctionCollection`).
        /// Reason: Cannot use internal init of `_LLMFunctionCollection` as default parameter within public ``LLMOpenAIRealtimeSchema/init(parameters:injectIntoContext:_:)``.
        nonisolated(unsafe) public static let emptyLLMFunctions: _LLMFunctionCollection = .init(functions: [])
    }

    let parameters: LLMOpenAIRealtimeParameters
    let functions: [String: any LLMFunction]
    public var injectIntoContext: Bool
    
    public init(
        parameters: LLMOpenAIRealtimeParameters,
        injectIntoContext: Bool = false,
        @LLMFunctionBuilder _ functionsCollection: () -> _LLMFunctionCollection = { Defaults.emptyLLMFunctions }
    ) {
        self.parameters = parameters
        self.injectIntoContext = injectIntoContext
        self.functions = functionsCollection().functions
    }
}
