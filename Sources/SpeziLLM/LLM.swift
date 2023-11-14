//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// The ``LLM`` protocol provides an abstraction layer for the usage of Large Language Models within the Spezi ecosystem.
public protocol LLM {
    /// The type of the ``LLM`` as represented by the ``LLMHostingType``.
    var type: LLMHostingType { get async }
    /// The state of the ``LLM`` indicated by the ``LLMState``.
    var state: LLMState { get async }
    
    
    /// Performs any setup-related actions for the ``LLM``.
    /// After this function completes, the state of the ``LLM`` should be ``LLMState/ready``.
    ///
    /// - Parameters:
    ///   - runnerConfig: The runner configuration as a ``LLMRunnerConfiguration``.
    func setup(runnerConfig: LLMRunnerConfiguration) async throws
    
    /// Performs the actual text generation functionality of the ``LLM`` based on an input prompt `String`.
    /// The result of the text generation is streamed via a Swift `AsyncThrowingStream` that is passed as a parameter.
    ///
    /// - Parameters:
    ///   - prompt: The input prompt `String` used for the text generation.
    ///   - continuation: A Swift `AsyncThrowingStream` enabling the streaming of the text generation.
    func generate(prompt: String, continuation: AsyncThrowingStream<String, Error>.Continuation) async
}
