//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import llama
import Semaphore
import Spezi
import SpeziLLM


/// LLM execution platform of an ``LLMLocalSchema``.
///
/// The ``LLMLocalPlatform`` turns a received ``LLMLocalSchema`` to an executable ``LLMLocalSession``.
/// Use ``LLMLocalPlatform/callAsFunction(with:)`` with an ``LLMLocalSchema`` parameter to get an executable ``LLMLocalSession`` that does the actual inference.
///
/// - Important: ``LLMLocalPlatform`` shouldn't be used directly but used via the `SpeziLLM` `LLMRunner` that delegates the requests towards the ``LLMLocalPlatform``.
/// The `SpeziLLM` `LLMRunner` must be configured with the ``LLMLocalPlatform`` within the Spezi `Configuration`.
///
/// - Tip: For more information, refer to the documentation of the `LLMPlatform` from SpeziLLM.
///
/// ### Usage
///
/// The example below demonstrates the setup of the ``LLMLocalPlatform`` within the Spezi `Configuration`.
///
/// ```
/// class TestAppDelegate: SpeziAppDelegate {
///     override var configuration: Configuration {
///         Configuration {
///             LLMRunner {
///                 LLMLocalPlatform()
///             }
///         }
///     }
/// }
/// ```
public actor LLMLocalPlatform: LLMPlatform, DefaultInitializable {
    /// Enforce only one concurrent execution of a local LLM.
    private let semaphore = AsyncSemaphore(value: 1)
    let configuration: LLMLocalPlatformConfiguration
    
    @MainActor public var state: LLMPlatformState = .idle
    
    
    /// Creates an instance of the ``LLMLocalPlatform``.
    ///
    /// - Parameters:
    ///     - configuration: The configuration of the platform.
    public init(configuration: LLMLocalPlatformConfiguration) {
        self.configuration = configuration
    }
    
    /// Convenience initializer for the ``LLMLocalPlatform``.
    public init() {
        self.init(configuration: .init())
    }
    
    
    public nonisolated func configure() {
        // Initialize the llama.cpp backend
        llama_backend_init(configuration.nonUniformMemoryAccess)
    }
    
    public func callAsFunction(with llmSchema: LLMLocalSchema) async -> LLMLocalSession {
        LLMLocalSession(self, schema: llmSchema)
    }
    
    nonisolated func exclusiveAccess() async throws {
        try await semaphore.waitUnlessCancelled()
        await MainActor.run {
            state = .processing
        }
    }
    
    nonisolated func signal() async {
        semaphore.signal()
        await MainActor.run {
            state = .idle
        }
    }
    
    
    deinit {
        // Frees the llama.cpp backend
        llama_backend_free()
    }
}
