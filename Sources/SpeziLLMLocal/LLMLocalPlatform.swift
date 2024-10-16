//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Spezi
import SpeziFoundation
import SpeziLLM
import MLX


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
        assertionFailure("SpeziLLMLocal: Code cannot be run on simulator.")
#endif
        
        MLX.GPU.set(cacheLimit: configuration.cacheLimit * 1024 * 1024)
        if let memoryLimit = configuration.memoryLimit {
            MLX.GPU.set(memoryLimit: memoryLimit.limit, relaxed: memoryLimit.relaxed)
        }
    }
    
    public nonisolated func callAsFunction(with llmSchema: LLMLocalSchema) -> LLMLocalSession {
        LLMLocalSession(self, schema: llmSchema)
    }
    
    deinit {
        MLX.GPU.clearCache()
    }
}
