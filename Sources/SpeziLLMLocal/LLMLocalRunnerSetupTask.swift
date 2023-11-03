//
// This source file is part of the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziLLM
import llama


public class LLMLocalRunnerSetupTask: LLMRunnerSetupTask {
    public let type: LLMHostingType = .local
    
    
    public func setupRunner(runnerConfig: LLMRunnerConfiguration) async throws {
        /// Initialize the llama.cpp backend.
        llama_backend_init(runnerConfig.numa)
    }
    
    
    deinit {
        /// Frees the llama.cpp backend.
        llama_backend_free()
    }
}
