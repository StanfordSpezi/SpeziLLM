//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import llama


extension LLMLocalSession {
    func setup(continuation: AsyncThrowingStream<String, Error>.Continuation) async -> Bool {
        Self.logger.debug("SpeziLLMLocal: Local LLM is being initialized")
        await MainActor.run {
            state = .loading
        }
        
        guard let model = llama_load_model_from_file(schema.modelPath.path().cString(using: .utf8), schema.parameters.llamaCppRepresentation) else {
            await finishGenerationWithError(LLMLocalError.modelNotFound, on: continuation)
            Self.logger.error("SpeziLLMLocal: Local LLM file could not be opened, indicating that the model file doesn't exist")
            return false
        }
        
        /// Check if model was trained for the configured context window size
        guard schema.contextParameters.contextWindowSize <= llama_n_ctx_train(model) else {
            await finishGenerationWithError(LLMLocalError.contextSizeMismatch, on: continuation)
            Self.logger.error("""
            SpeziLLMLocal: Model was trained on only \(llama_n_ctx_train(model), privacy: .public) context tokens,
            not the configured \(self.schema.contextParameters.contextWindowSize, privacy: .public) context tokens
            """)
            return false
        }
        
        self.model = model
        
        await MainActor.run {
            state = .ready
        }
        Self.logger.debug("SpeziLLMLocal: Local LLM finished initializing, now ready to use")
        return true
    }
}
