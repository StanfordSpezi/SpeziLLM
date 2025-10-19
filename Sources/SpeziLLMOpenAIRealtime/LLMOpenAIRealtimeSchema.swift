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

/// Defines the type and configuration of the ``LLMOpenAIRealtimeSession``.
///
/// The ``LLMOpenAIRealtimeSchema`` is used as a configuration for the to-be-used Realtime OpenAI LLM. It contains all information necessary for the creation of an executable ``LLMOpenAIRealtimeSession``.
/// It is bound to a ``LLMOpenAIRealtimePlatform`` that is responsible for turning the ``LLMOpenAIRealtimeSchema`` to an ``LLMOpenAIRealtimeSession``.
///
/// - Tip: ``LLMOpenAIRealtimeSchema`` also enables the function calling mechanism to establish a structured, bidirectional, and reliable communication between the OpenAI LLMs and external tools. For details, refer to `LLMFunction` and `LLMFunction/Parameter` from SpeziLLMOpenAI or see [Function Calling](https://swiftpackageindex.com/StanfordSpezi/SpeziLLM/main/documentation/spezillmopenai/functioncalling).
///
/// - Tip: For more information, refer to the documentation of the `LLMSchema` from SpeziLLM.
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
    
    /// Creates an instance of the ``LLMOpenAIRealtimeSchema`` containing all necessary configuration for Realtime OpenAI LLM inference.
    ///
    /// - Parameters:
    ///    - parameters: Parameters of the Realtime OpenAI LLM client.
    ///    - modelParameters: Parameters of the used Realtime OpenAI LLM.
    ///    - injectIntoContext: Indicates if the ``LLMOpenAIRealtimeSession`` inference output (text and audio based inference), as well as user transcripts
    ///                         should automatically be inserted into the ``LLMOpenAIRealtimeSession/context``, defaults to `true`.
    ///    - functionsCollection: LLM Functions (tools) used for the OpenAI function calling mechanism.
    public init(
        parameters: LLMOpenAIRealtimeParameters,
        injectIntoContext: Bool = true,
        @LLMFunctionBuilder _ functionsCollection: () -> _LLMFunctionCollection = { Defaults.emptyLLMFunctions }
    ) {
        self.parameters = parameters
        self.injectIntoContext = injectIntoContext
        self.functions = functionsCollection().functions
    }
}
