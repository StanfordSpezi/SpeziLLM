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


public final class LLMOpenAIRealtimePlatform: LLMPlatform {
    /// A `Logger` that logs important information from the ``LLMOpenAIPlatform``.
    static let logger = Logger(subsystem: "edu.stanford.spezi", category: "SpeziLLMOpenAIRealtime")
    
    /// Configuration of the platform.
    public let configuration: LLMOpenAIRealtimePlatformConfiguration
    /// Queue that processed the LLM inference tasks in a structured concurrency manner.
    let queue: LLMInferenceQueue<String>

    @MainActor public var state: LLMPlatformState {
        self.queue.platformState
    }


    public init(configuration: LLMOpenAIRealtimePlatformConfiguration) {
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
        LLMOpenAIRealtimeSession()
    }

}
