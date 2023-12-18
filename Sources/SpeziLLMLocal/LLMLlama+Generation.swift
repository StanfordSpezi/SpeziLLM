//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import llama
import SpeziLLM


/// Extension of ``LLMLlama`` handling the text generation.
extension LLMLlama {
    /// Typealias for the llama.cpp `llama_token`.
    typealias LLMLlamaToken = llama_token
    
    
    /// Based on the input prompt, generate the output with llama.cpp
    ///
    /// - Parameters:
    ///   - continuation: A Swift `AsyncThrowingStream` that streams the generated output.
    func _generate( // swiftlint:disable:this identifier_name function_body_length cyclomatic_complexity
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async {
        await MainActor.run {
            self.state = .generating
        }
        
        // Log the most important parameters of the LLM
        Self.logger.debug("SpeziLLMLocal: n_length = \(self.parameters.maxOutputLength, privacy: .public), n_ctx = \(self.contextParameters.contextWindowSize, privacy: .public), n_batch = \(self.contextParameters.batchSize, privacy: .public), n_kv_req = \(self.parameters.maxOutputLength, privacy: .public)")
        
        // Allocate new model context, if not already present
        if self.modelContext == nil {
            guard let context = llama_new_context_with_model(model, self.contextParameters.llamaCppRepresentation) else {
                Self.logger.error("SpeziLLMLocal: Failed to initialize context")
                await finishGenerationWithError(LLMLlamaError.generationError, on: continuation)
                return
            }
            self.modelContext = context
        }

        // Check if the maximal output generation length is smaller or equals to the context window size.
        guard self.parameters.maxOutputLength <= self.contextParameters.contextWindowSize else {
            Self.logger.error("SpeziLLMLocal: Error: n_kv_req \(self.parameters.maxOutputLength, privacy: .public) > n_ctx, the required KV cache size is not big enough")
            await finishGenerationWithError(LLMLlamaError.generationError, on: continuation)
            return
        }
        
        // Tokenizes the entire context of the `LLM?
        guard let tokens = try? await tokenize() else {
            Self.logger.error("""
            SpeziLLMLocal: Tokenization failed as illegal context exists.
            Ensure the content of the context is structured in: System Prompt, User prompt, and an
            arbitrary number of assistant responses and follow up user prompts.
            """)
            await finishGenerationWithError(LLMLlamaError.illegalContext, on: continuation)
            return
        }
        
        // Check if the input token count is smaller than the context window size decremented by 4 (space for end tokens).
        guard tokens.count <= self.contextParameters.contextWindowSize - 4 else {
            Self.logger.error("""
            SpeziLLMLocal: Input prompt is too long with \(tokens.count, privacy: .public) tokens for the configured
            context window size of \(self.contextParameters.contextWindowSize, privacy: .public) tokens.
            """)
            await finishGenerationWithError(LLMLlamaError.generationError, on: continuation)
            return
        }
        
        // Clear the KV cache in order to free up space for the incoming prompt (as we inject the entire history of the chat again)
        llama_kv_cache_clear(self.modelContext)
        
        var batch = llama_batch_init(Int32(tokens.count), 0, 1)
        defer {
            llama_batch_free(batch)
        }
        
        // Evaluate the initial prompt
        for (tokenIndex, token) in tokens.enumerated() {
            llama_batch_add(&batch, token, Int32(tokenIndex), getLlamaSeqIdVector(), false)
        }
        // llama_decode will output logits only for the last token of the prompt
        batch.logits[Int(batch.n_tokens) - 1] = 1
        
        if llama_decode(self.modelContext, batch) != 0 {
            await finishGenerationWithError(LLMLlamaError.generationError, on: continuation)
            return
        }
        
        // Batch already includes tokens from the input prompt
        var batchTokenIndex = batch.n_tokens
        var decodedTokens = 0

        // Calculate the token generation rate
        let startTime = Date()
        
        while decodedTokens <= self.parameters.maxOutputLength {
            let nextTokenId = sample(batchSize: batch.n_tokens)
            
            // Either finish the generation once EOS token appears, the maximum output length of the answer is reached or the context window is reached
            if nextTokenId == llama_token_eos(self.model)
                || decodedTokens == self.parameters.maxOutputLength
                || batchTokenIndex == self.contextParameters.contextWindowSize {
                continuation.finish()
                await MainActor.run {
                    self.state = .ready
                }
                return
            }
            
            var nextStringPiece = String(llama_token_to_piece(self.modelContext, nextTokenId))
            // As first character is sometimes randomly prefixed by a single space (even though prompt has an additional character)
            if decodedTokens == 0 && nextStringPiece.starts(with: " ") {
                nextStringPiece = String(nextStringPiece.dropFirst())
            }
            
            // Yield the response from the model to the Stream
            Self.logger.debug("""
            SpeziLLMLocal: Yielded token: \(nextStringPiece, privacy: .public)
            """)
            continuation.yield(nextStringPiece)
            
            // Prepare the next batch
            llama_batch_clear(&batch)
            
            // Push generated output token for the next evaluation round
            llama_batch_add(&batch, nextTokenId, batchTokenIndex, getLlamaSeqIdVector(), true)
            
            decodedTokens += 1
            batchTokenIndex += 1
            
            // Evaluate the current batch with the transformer model
            let decodeOutput = llama_decode(self.modelContext, batch)
            if decodeOutput != 0 {      // = 0 Success, > 0 Warning, < 0 Error
                Self.logger.error("SpeziLLMLocal: Decoding of generated output failed. Output: \(decodeOutput, privacy: .public)")
                await finishGenerationWithError(LLMLlamaError.generationError, on: continuation)
                return
            }
        }
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        
        Self.logger.debug("SpeziLLMLocal: Decoded \(decodedTokens, privacy: .public) tokens in \(String(format: "%.2f", elapsedTime), privacy: .public) s, speed: \(String(format: "%.2f", Double(decodedTokens) / elapsedTime), privacy: .public)) t/s")

        llama_print_timings(self.modelContext)
         
        continuation.finish()
        await MainActor.run {
            self.state = .ready
        }
    }
}
