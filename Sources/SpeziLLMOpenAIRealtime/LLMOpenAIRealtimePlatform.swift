//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import os
import Spezi
import SpeziFoundation
import SpeziKeychainStorage
import SpeziLLM
import SpeziLLMOpenAI


public final class LLMOpenAIRealtimePlatform: LLMPlatform {
    /// A `Logger` that logs important information from the ``LLMOpenAIPlatform``.
    static let logger = Logger(subsystem: "edu.stanford.spezi", category: "SpeziLLMOpenAIRealtime")
    
    /// Configuration of the platform.
    public let configuration: LLMOpenAIPlatformConfiguration
    /// Queue that processed the LLM inference tasks in a structured concurrency manner.
    let queue: LLMInferenceQueue<String>

    @Dependency(KeychainStorage.self) private var keychainStorage
    @MainActor public var state: LLMPlatformState {
        self.queue.platformState
    }

    /// Creates an instance of the ``LLMOpenAIRealtimePlatform``.
    ///
    /// - Parameters:
    ///     - configuration: The configuration of the platform.
    public init(configuration: LLMOpenAIPlatformConfiguration) {
        self.configuration = configuration
        self.queue = LLMInferenceQueue(
            maxConcurrentTasks: configuration.concurrentStreams,
            taskPriority: configuration.taskPriority
        )
    }
    
    public func run() async {
        do {
            // Run the LLM task queue
            try await self.queue.runQueue()
        } catch is CancellationError {
            // No-op, shutdown
        } catch {
            fatalError("Inconsistent state of the LLMOpenAIRealtimePlatform: \(error)")
        }
    }
    
    public func callAsFunction(with llmSchema: LLMOpenAIRealtimeSchema) -> LLMOpenAIRealtimeSession {
        LLMOpenAIRealtimeSession(self, schema: llmSchema, keychainStorage: keychainStorage)
    }
    
    deinit {
        self.queue.shutdown()   // Safeguard shutdown of queue (should happen upon `ServiceModule/run() cancellation)
    }
}

extension LLMOpenAIRealtimePlatform: @unchecked Sendable {}     // unchecked because of the `Dependency` property wrapper storage
