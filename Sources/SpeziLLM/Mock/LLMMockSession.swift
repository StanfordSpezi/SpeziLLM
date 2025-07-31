//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Observation
import SpeziChat


/// A mock ``LLMSession``, used for testing purposes.
///
/// The ``LLMMockSession`` is created by the configuration defined in the ``LLMMockSchema``.
/// The ``LLMMockSession`` is then executed by the ``LLMMockPlatform``.
///
/// The ``LLMMockSession`` generates an example output String ("Mock Message from SpeziLLM!") with a 1 second startup time
/// as well as 0.5 seconds between each `String` piece generation.
@Observable
public final class LLMMockSession: LLMSession, Sendable {
    let platform: LLMMockPlatform
    let schema: LLMMockSchema

    /// Holds the currently generating continuations so that we can cancel them if required.
    let continuationHolder = LLMInferenceQueueContinuationHolder()

    @MainActor public var state: LLMState = .uninitialized
    @MainActor public var context: LLMContext = []
    
    
    /// Initializer for the ``LLMMockSession``.
    ///
    /// - Parameters:
    ///     - platform: The mock LLM platform.
    ///     - schema: The mock LLM schema.
    init(_ platform: LLMMockPlatform, schema: LLMMockSchema) {
        self.platform = platform
        self.schema = schema
    }
    
    
    @discardableResult
    public func generate() async throws -> AsyncThrowingStream<String, any Error> {
        try self.platform.queue.submit { continuation in
            // store the continuation so that we can cancel it later
            let id = self.continuationHolder.add(continuation)

            await MainActor.run {
                self.state = .loading
            }
            try? await Task.sleep(for: .seconds(1))
            if await self.checkCancellation(on: continuation) {
                return
            }

            await MainActor.run {
                self.state = .generating
            }

            // Generate mock messages
            let tokens = ["Mock ", "Message ", "from ", "SpeziLLM!"]
            for token in tokens {
                try? await Task.sleep(for: .milliseconds(500))
                if await self.checkCancellation(on: continuation) {
                    return
                }

                if case .terminated = continuation.yield(token) {
                    // no cleanup necessary as we're breaking the loop
                    break
                }

                if self.schema.injectIntoContext {
                    await MainActor.run {
                        self.context.append(assistantOutput: token)
                    }
                }
            }

            continuation.finish()
            await MainActor.run {
                self.context.completeAssistantStreaming()
                self.state = .ready
            }

            // remove continuation from holder (does not cancel it)
            self.continuationHolder.remove(id: id)
        }
    }
    
    public func cancel() {
        // cancel all currently generating continuations
        self.continuationHolder.cancelAll()
    }
    
    
    deinit {
        self.cancel()
    }
}
