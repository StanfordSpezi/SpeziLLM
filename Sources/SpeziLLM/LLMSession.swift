//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziChat


public protocol LLMSession: AnyObject {
    /// The state of the ``LLMSession`` indicated by the ``LLMState``.
    @MainActor var state: LLMState { get set }
    /// The current context state of the ``LLMSession``, includes the entire prompt history including system prompts, user input, and model responses.
    @MainActor var context: Chat { get set }
    
    
    @discardableResult
    func generate() async throws -> AsyncThrowingStream<String, Error>
    
    func cancel()
}


extension LLMSession {
    /// Finishes the continuation with an error and sets the ``LLM/state`` to the respective error (on the main actor).
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
    
    public func checkCancellation(on continuation: AsyncThrowingStream<String, Error>.Continuation) async -> Bool {
        if Task.isCancelled {
            await finishGenerationWithError(CancellationError(), on: continuation)
            return true
        }
        
        return false
    }
}
