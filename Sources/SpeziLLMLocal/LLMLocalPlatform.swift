//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import MLX
import Spezi
import SpeziFoundation
import SpeziLLM
#if targetEnvironment(simulator)
import OSLog
#endif

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
/// ```swift
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
#if targetEnvironment(simulator)
        Logger(
            subsystem: "Spezi",
            category: "LLMLocalPlatform"
        ).warning("SpeziLLMLocal is only supported on physical devices. Use `LLMMockPlatform` instead.")
#else
        if let cacheLimit = configuration.cacheLimit {
            MLX.GPU.set(cacheLimit: cacheLimit * 1024 * 1024)
        }
        if let memoryLimit = configuration.memoryLimit {
            MLX.GPU.set(memoryLimit: memoryLimit.limit, relaxed: memoryLimit.relaxed)
        }
#endif
    }
    
    public nonisolated func callAsFunction(with llmSchema: LLMLocalSchema) -> some LLMSession {
        #if targetEnvironment(simulator)
        LLMLocalMockSession(self, schema: llmSchema)
        #else
        LLMLocalSession(self, schema: llmSchema)
        #endif
    }
    
    deinit {
        MLX.GPU.clearCache()
    }
}
