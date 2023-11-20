//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import llama
import Spezi
import SpeziLLM


/// The ``LLMLocalRunnerSetupTask`` sets up the local environment in order to execute Spezi `LLM`s.
/// It needs to be stated within the `LLMRunner` initializer.
///
/// ```swift
/// class LocalLLMAppDelegate: SpeziAppDelegate {
///     override var configuration: Configuration {
///         Configuration {
///             // Configure the runner responsible for executing local LLMs
///             LLMRunner {
///                 LLMLocalRunnerSetupTask()
///             }
///         }
///     }
/// }
public class LLMLocalRunnerSetupTask: LLMRunnerSetupTask, DefaultInitializable {
    public let type: LLMHostingType = .local
    
    
    public required init() { }
    
    
    public func setupRunner(runnerConfig: LLMRunnerConfiguration) async throws {
        /// Initialize the llama.cpp backend.
        llama_backend_init(runnerConfig.nonUniformMemoryAccess)
    }
    
    
    deinit {
        /// Frees the llama.cpp backend.
        llama_backend_free()
    }
}
