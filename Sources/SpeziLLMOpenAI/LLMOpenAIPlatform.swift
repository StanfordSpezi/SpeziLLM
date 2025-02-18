//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import os
import Spezi
import SpeziFoundation
import SpeziKeychainStorage
import SpeziLLM

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
public class LLMOpenAIPlatform: LLMPlatform, DefaultInitializable, @unchecked Sendable {
    /// A Swift Logger that logs important information from the ``LLMLocalSession``.
    static let logger = Logger(subsystem: "edu.stanford.spezi", category: "SpeziLLMOpenAI")
    
    /// Enforce an arbitrary number of concurrent execution jobs of OpenAI LLMs.
    private let semaphore: AsyncSemaphore
    let configuration: LLMOpenAIPlatformConfiguration
    
    @MainActor public var state: LLMPlatformState = .idle
    @Dependency(LLMOpenAITokenSaver.self) private var tokenSaver
    @Dependency(KeychainStorage.self) private var keychainStorage
    
    /// Creates an instance of the ``LLMOpenAIPlatform``.
    ///
    /// - Parameters:
    ///     - configuration: The configuration of the platform.
    public init(configuration: LLMOpenAIPlatformConfiguration) {
        self.configuration = configuration
        self.semaphore = AsyncSemaphore(value: configuration.concurrentStreams)
    }
    
    /// Convenience initializer for the ``LLMOpenAIPlatform``.
    public required convenience init() {
        self.init(configuration: .init())
    }
    
    
    public func configure() {
        // If token passed via init
        if let apiToken = configuration.apiToken {
            do {
                try keychainStorage.store(
                    Credentials(username: LLMOpenAIConstants.credentialsUsername, password: apiToken),
                    for: .openAIKey
                )
            } catch {
                preconditionFailure("""
                SpeziLLMOpenAI: Configured OpenAI API token could not be stored within the SpeziSecureStorage.
                """)
            }
        }
    }
    
    public func callAsFunction(with llmSchema: LLMOpenAISchema) -> LLMOpenAISession {
        LLMOpenAISession(self, schema: llmSchema, keychainStorage: keychainStorage)
    }
    
    func exclusiveAccess() async throws {
        try await semaphore.waitCheckingCancellation()
        
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
