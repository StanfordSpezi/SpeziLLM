//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import OSLog
import Spezi
import SpeziFoundation
import SpeziKeychainStorage
import SpeziLLM


/// A `LLMPlatform` that is interoperable with the OpenAI API.
public final class LLMOpenAILikePlatform<PlatformDefinition: LLMOpenAILikePlatformDefinition>: LLMPlatform, @unchecked Sendable {
    public typealias Schema = LLMOpenAILikeSchema<PlatformDefinition>
    public typealias Session = LLMOpenAILikeSession<PlatformDefinition>

    /// Configuration of the platform.
    public let configuration: LLMOpenAILikePlatformConfiguration<PlatformDefinition>
    /// Queue that processed the LLM inference tasks in a structured concurrency manner.
    let queue: LLMInferenceQueue<String>

    @Dependency(KeychainStorage.self) private var keychainStorage
    @MainActor public var state: LLMPlatformState {
        self.queue.platformState
    }

    /// Creates an instance of the ``LLMOpenAIPlatform``.
    ///
    /// - Parameters:
    ///     - configuration: The configuration of the platform.
    public init(configuration: LLMOpenAILikePlatformConfiguration<PlatformDefinition>) {
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
            fatalError("Inconsistent state of the LLMOpenAIPlatform: \(error)")
        }
    }

    public func callAsFunction(with llmSchema: LLMOpenAILikeSchema<PlatformDefinition>) -> LLMOpenAILikeSession<PlatformDefinition> {
        LLMOpenAILikeSession<PlatformDefinition>(self, schema: llmSchema, keychainStorage: keychainStorage)
    }


    deinit {
        self.queue.shutdown()   // Safeguard shutdown of queue (should happen upon `ServiceModule/run() cancellation)
    }
}
