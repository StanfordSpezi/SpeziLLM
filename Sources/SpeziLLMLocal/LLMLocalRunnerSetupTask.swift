//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import llama
import SpeziLLM


public class LLMLocalRunnerSetupTask: LLMRunnerSetupTask {
    public let type: LLMHostingType = .local
    
    
    public func setupRunner(runnerConfig: LLMRunnerConfiguration) async throws {
        /// Initialize the llama.cpp backend.
        llama_backend_init(runnerConfig.nonUniformMemoryAccess)
    }
    
    
    deinit {
        /// Frees the llama.cpp backend.
        llama_backend_free()
    }
}
