//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziChat


/// The ``LLM`` protocol provides an abstraction layer for the usage of Large Language Models within the Spezi ecosystem,
/// regardless of the execution locality (local or remote) or the specific model type.
/// Developers can use the ``LLM`` protocol to conform their LLM interface implementations to a standard which is consistent throughout the Spezi ecosystem.
///
/// - Important: An ``LLM`` shouldn't be executed on it's own but always used together with the ``LLMRunner``.
/// Please refer to the ``LLMRunner`` documentation for a complete code example.
///
/// ### Usage
///
/// An example conformance of the ``LLM`` looks like the code sample below (lots of details were omitted for simplicity).
/// The key point is the need to implement the ``LLM/setup(runnerConfig:)`` as well as the ``LLM/generate(prompt:continuation:)`` functions, whereas the ``LLM/setup(runnerConfig:)`` has an empty default implementation as not every ``LLMHostingType`` requires the need for a setup closure.
///
/// ```swift
/// @Observable
/// class LLMTest: LLM {
///     var type: LLMHostingType = .local
///     @MainActor public var state: LLMState = .uninitialized
///     @MainActor public var context: Chat = []
///
///     func setup(/* */) async {}
///     func generate(/* */) async {}
/// }
/// ```
public protocol LLM: AnyObject {
    /// The type of the ``LLM`` as represented by the ``LLMHostingType``.
    var type: LLMHostingType { get }
    /// The state of the ``LLM`` indicated by the ``LLMState``.
    @MainActor var state: LLMState { get set }
    /// The current context state of the ``LLM``, includes the entire prompt history including system prompts, user input, and model responses.
    @MainActor var context: Chat { get set }
    
    
    /// Performs any setup-related actions for the ``LLM``.
    /// After this function completes, the state of the ``LLM`` should be ``LLMState/ready``.
    ///
    /// - Parameters:
    ///   - runnerConfig: The runner configuration as a ``LLMRunnerConfiguration``.
    func setup(runnerConfig: LLMRunnerConfiguration) async throws
    
    /// Performs the actual text generation functionality of the ``LLM`` based on the ``LLM/context``.
    /// The result of the text generation is streamed via a Swift `AsyncThrowingStream` that is passed as a parameter.
    ///
    /// - Parameters:
    ///   - continuation: A Swift `AsyncThrowingStream` enabling the streaming of the text generation.
    func generate(continuation: AsyncThrowingStream<String, Error>.Continuation) async
}


extension LLM {
    /// Finishes the continuation with an error and sets the ``LLMLlama/state`` to the respective error (on the main actor).
    ///
    /// - Parameters:
    ///   - error: The error that occurred.
    ///   - continuation: The `AsyncThrowingStream` that streams the generated output.
    public func finishGenerationWithError<E: LLMError>(_ error: E, on continuation: AsyncThrowingStream<String, Error>.Continuation) async {
        continuation.finish(throwing: error)
        await MainActor.run {
            self.state = .error(error: error)
        }
    }
}
