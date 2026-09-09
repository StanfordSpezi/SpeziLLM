//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Spezi
import SpeziFoundation
import SpeziLLM


/// LLM execution platform backed by Apple's `FoundationModels` framework.
///
/// The platform turns a received ``LLMFoundationModelsSchema`` into an executable
/// ``LLMFoundationModelsSession`` by way of the standard SpeziLLM `LLMRunner`.
///
/// - Important: The underlying APIs require iOS 26+, macOS 26+, or visionOS 26+ and an Apple Intelligence-eligible
/// device. On older OS versions, sessions surface ``LLMFoundationModelsError/frameworkUnavailable``.
///
/// ### Usage
///
/// ```swift
/// class TestAppDelegate: SpeziAppDelegate {
///     override var configuration: Configuration {
///         Configuration {
///             LLMRunner {
///                 LLMFoundationModelsPlatform()
///             }
///         }
///     }
/// }
/// ```
public final class LLMFoundationModelsPlatform: LLMPlatform, DefaultInitializable {
    /// Configuration of the platform.
    public let configuration: LLMFoundationModelsPlatformConfiguration
    /// Queue that orders LLM inference tasks.
    let queue: LLMInferenceQueue<String>


    @MainActor public var state: LLMPlatformState {
        self.queue.platformState
    }


    /// Creates an ``LLMFoundationModelsPlatform`` with a custom configuration.
    public init(configuration: LLMFoundationModelsPlatformConfiguration) {
        self.configuration = configuration
        self.queue = LLMInferenceQueue(
            maxConcurrentTasks: 1,
            taskPriority: configuration.taskPriority
        )
    }

    /// Creates an ``LLMFoundationModelsPlatform`` with the default configuration.
    public convenience init() {
        self.init(configuration: .init())
    }

    public func run() async {
        do {
            try await self.queue.runQueue()
        } catch is CancellationError {
            // No-op, shutdown.
        } catch {
            fatalError("Inconsistent state of the LLMFoundationModelsPlatform: \(error)")
        }
    }

    public func callAsFunction(with llmSchema: LLMFoundationModelsSchema) -> LLMFoundationModelsSession {
        LLMFoundationModelsSession(self, schema: llmSchema)
    }

    deinit {
        self.queue.shutdown()
    }
}
