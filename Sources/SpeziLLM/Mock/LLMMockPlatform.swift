//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


/// A mock ``LLMPlatform``, used for testing purposes.
///
/// The platform is associated with the ``LLMMockSchema`` and enables the execution of the ``LLMMockSession``.
public final class LLMMockPlatform: LLMPlatform {
    /// Queue that processed the LLM inference tasks in a structured concurrency manner.
    let queue: LLMInferenceQueue<String>


    @MainActor public var state: LLMPlatformState {
        self.queue.platformState
    }

    
    /// Initializer for the ``LLMMockPlatform``.
    public init() {
        self.queue = LLMInferenceQueue(
            maxConcurrentTasks: 1,
            taskPriority: .userInitiated
        )
    }


    public func run() async {
        do {
            // Run the LLM task queue
            try await self.queue.runQueue()
        } catch is CancellationError {
            // No-op, shutdown
        } catch {
            fatalError("Inconsistent state of the LLMOpenAIPlatform: \(error)")
        }
    }

    public func callAsFunction(with: LLMMockSchema) -> LLMMockSession {
        LLMMockSession(self, schema: with)
    }


    deinit {
        self.queue.shutdown()   // Safeguard shutdown of queue (should happen upon `ServiceModule/run() cancellation)
    }
}
