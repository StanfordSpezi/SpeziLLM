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


/// LLM execution platform of an ``LLMOpenAIRealtimeSchema``.
///
/// The ``LLMOpenAIRealtimePlatform`` turns a received ``LLMOpenAIRealtimeSchema`` to an executable ``LLMOpenAIRealtimeSession``.
/// Use ``LLMOpenAIRealtimePlatform/callAsFunction(with:)`` with an ``LLMOpenAIRealtimeSchema`` parameter to get an executable ``LLMOpenAIRealtimeSession`` that does the actual inference.
///
/// The platform can be configured with the `LLMOpenAIPlatformConfiguration` from `SpeziLLMOpenAI`, enabling developers to specify properties like a custom server `URL`s, API tokens, the retry policy or timeouts.
///
/// - Important: ``LLMOpenAIRealtimePlatform`` shouldn't be used directly but used via the `SpeziLLM` `LLMRunner` that delegates the requests towards the ``LLMOpenAIRealtimePlatform``.
/// The `SpeziLLM` `LLMRunner` must be configured with the ``LLMOpenAIRealtimePlatform`` within the Spezi `Configuration`.
///
/// - Tip: For more information, refer to the documentation of the `LLMPlatform` from SpeziLLM.
///
/// ### Usage
///
/// The example below demonstrates the setup of the ``LLMOpenAIRealtimePlatform`` within the Spezi `Configuration`.
///
/// ```swift
/// class TestAppDelegate: SpeziAppDelegate {
///     override var configuration: Configuration {
///         Configuration {
///             LLMRunner {
///                 LLMOpenAIRealtimePlatform()
///             }
///         }
///     }
/// }
/// ```
public final class LLMOpenAIRealtimePlatform: LLMPlatform, @unchecked Sendable { // unchecked because of the `Dependency` property wrapper storage
    /// A `Logger` that logs important information from the ``LLMOpenAIPlatform``.
    private static let logger = Logger(subsystem: "edu.stanford.spezi", category: "SpeziLLMOpenAIRealtime")
    
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
