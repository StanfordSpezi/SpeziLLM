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

                continuation.yield(token)
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
        }
    }
    
    public func cancel() {
        // TODO: Cancel task in the inference queue
    }
    
    
    deinit {
        self.cancel()
    }
}
