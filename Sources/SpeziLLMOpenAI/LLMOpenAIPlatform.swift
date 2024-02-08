//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Semaphore
import Spezi
import SpeziLLM
import SpeziSecureStorage


/// LLM execution platform of an ``LLMOpenAISchema``.
///
/// The ``LLMOpenAIPlatform`` turns a received ``LLMOpenAISchema`` to an executable ``LLMOpenAISession``.
/// Use ``LLMOpenAIPlatform/callAsFunction(with:)`` with an ``LLMOpenAISchema`` parameter to get an executable ``LLMOpenAISession`` that does the actual inference.
///
/// - Important: ``LLMOpenAIPlatform`` shouldn't be used directly but used via the `SpeziLLM` `LLMRunner` that delegates the requests towards the ``LLMOpenAIPlatform``.
/// The `SpeziLLM` `LLMRunner` must be configured with the ``LLMOpenAIPlatform`` within the Spezi `Configuration`.
///
/// - Tip: For more information, refer to the documentation of the `LLMPlatform` from SpeziLLM.
///
/// ### Usage
///
/// The example below demonstrates the setup of the ``LLMOpenAIPlatform`` within the Spezi `Configuration`.
///
/// ```swift
/// class TestAppDelegate: SpeziAppDelegate {
///     override var configuration: Configuration {
///         Configuration {
///             LLMRunner {
///                 LLMOpenAIPlatform()
///             }
///         }
///     }
/// }
/// ```
public actor LLMOpenAIPlatform: LLMPlatform, DefaultInitializable {
    /// Enforce an arbitrary number of concurrent execution jobs of OpenAI LLMs.
    private let semaphore: AsyncSemaphore
    let configuration: LLMOpenAIPlatformConfiguration
    
    @MainActor public var state: LLMPlatformState = .idle
    @Dependency private var tokenSaver: LLMOpenAITokenSaver
    @Dependency private var secureStorage: SecureStorage
    
    
    /// Creates an instance of the ``LLMOpenAIPlatform``.
    ///
    /// - Parameters:
    ///     - configuration: The configuration of the platform.
    public init(configuration: LLMOpenAIPlatformConfiguration) {
        self.configuration = configuration
        self.semaphore = AsyncSemaphore(value: configuration.concurrentStreams)
    }
    
    /// Convenience initializer for the ``LLMOpenAIPlatform``.
    public init() {
        self.init(configuration: .init())
    }
    
    
    public nonisolated func configure() {
        Task {
            // If token passed via init
            if let apiToken = configuration.apiToken {
                try await secureStorage.store(
                    credentials: Credentials(username: LLMOpenAIConstants.credentialsUsername, password: apiToken),
                    server: LLMOpenAIConstants.credentialsServer
                )
            }
        }
    }
    
    public func callAsFunction(with llmSchema: LLMOpenAISchema) async -> LLMOpenAISession {
        LLMOpenAISession(self, schema: llmSchema, secureStorage: secureStorage)
    }
    
    func exclusiveAccess() async throws {
        try await semaphore.waitUnlessCancelled()
        
        if await state != .processing {
            await MainActor.run {
                state = .processing
            }
        }
    }
    
    func signal() async {
        let otherTasksWaiting = semaphore.signal()
        
        if !otherTasksWaiting {
            await MainActor.run {
                state = .idle
            }
        }
    }
}
