//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziChat


/// Represents an LLM in execution.
///
/// The ``LLMSession`` is the executable version of the LLM containing context and state as defined by the ``LLMSchema``.
/// The ``LLMPlatform`` is responsible for turning the ``LLMSchema`` towards the ``LLMSession`` and is able to pass arbitrary dependencies to the ``LLMSession``.
///
/// ``LLMSession`` does the heavy lifting of actually providing the inference logic of the LLMs to generate `String`-based output on the ``LLMSession/context`` input.
/// The inference is started by ``LLMSession/generate()``, returning an `AsyncThrowingStream` and can be cancelled via ``LLMSession/cancel()``.
///
/// The ``LLMSession`` exposes its current state via the ``LLMSession/context`` property, containing all the conversational history with the LLM.
/// In addition, the ``LLMSession/state`` indicates the current lifecycle state of the LLM, so for example ``LLMState/ready`` or ``LLMState/generating``.
/// Both of these properties should be bound to the `MainActor` in order to allow for seamless SwiftUI `View` updates.
///
/// The actual compute-intensive inference should be performed within a `Task`. The `Task` instance should be stored within the ``LLMSession`` in order to properly cancel the task at hand if requested to do so.
///
/// - Warning: The ``LLMSession`` shouldn't be created manually but always through an ``LLMPlatform`` which in turn is automatically chosen for a given ``LLMSchema`` via the ``LLMRunner``.
///
/// - Important: A ``LLMSession`` is a `class`-bound `protocol` and must therefore be implemented by a Swift `class`.
/// In addition, the ``LLMSession`` must be annotated with the `@Observable` macro in order to track the ``LLMSession/context`` changes, otherwise a runtime crash will occur during inference.
///
/// ### Usage
///
/// The example below demonstrates a concrete implementation of the ``LLMSession`` with the ``LLMMockPlatform`` and ``LLMMockSchema``.
///
/// ```swift
/// @Observable
/// public class LLMMockSession: LLMSession {
///     let platform: LLMMockPlatform
///     let schema: LLMMockSchema
///     private var task: Task<(), Never>?
///
///     @MainActor public var state: LLMState = .uninitialized
///     @MainActor public var context: Chat = []
///
///     init(_ platform: LLMMockPlatform, schema: LLMMockSchema) {
///         self.platform = platform
///         self.schema = schema
///     }
///
///     @discardableResult
///     public func generate() async throws -> AsyncThrowingStream<String, Error> {
///         let (stream, continuation) = AsyncThrowingStream.makeStream(of: String.self)
///
///         task = Task {
///             // Yield string pieces on the continuation
///         }
///
///         return stream
///     }
///
///     public func cancel() {
///         task?.cancel()
///     }
/// }
/// ```
public protocol LLMSession: AnyObject, Sendable {
    /// The state of the ``LLMSession`` indicated by the ``LLMState``.
    @MainActor var state: LLMState { get set }
    /// The current context state of the ``LLMSession``, includes the entire prompt history including system prompts, user input, and model responses.
    @MainActor var context: Chat { get set }
    
    
    /// Starts the inference of the ``LLMSession`` based on the ``LLMSession/context``.
    ///
    /// - Returns: An `AsyncThrowingStream` that yields the generated `String` pieces from the LLM.
    @discardableResult
    func generate() async throws -> AsyncThrowingStream<String, Error>
    
    /// Cancels the current inference of the ``LLMSession``.
    func cancel()
}


extension LLMSession {
    /// Finishes the continuation with an error and sets the ``LLMSession/state`` to the respective error.
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
    
    /// Checks for cancellation of the current `Task` and sets the `CancellationError` error on the continuation as well as the ``LLMSession/state``.
    ///
    /// - Parameters:
    ///   - continuation: The `AsyncThrowingStream` that streams the generated output.
    ///
    /// - Returns: Boolean flag indicating if the `Task` has been cancelled, `true` if has been cancelled, `false` otherwise.
    public func checkCancellation(on continuation: AsyncThrowingStream<String, Error>.Continuation) async -> Bool {
        if Task.isCancelled {
            await finishGenerationWithError(CancellationError(), on: continuation)
            return true
        }
        
        return false
    }
}
