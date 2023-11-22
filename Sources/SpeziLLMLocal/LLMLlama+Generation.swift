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
import SpeziLLMLocalHelpers


/// Extension of ``LLMLlama`` handling the text generation.
extension LLMLlama {
    /// Typealias for the llama.cpp `llama_token`.
    typealias LLMLlamaToken = llama_token
    
    
    /// Based on the input prompt, generate the output with llama.cpp
    ///
    /// - Parameters:
    ///   - prompt: The input `String` prompt.
    ///   - continuation: A Swift `AsyncThrowingStream` that streams the generated output.
    func _generate( // swiftlint:disable:this identifier_name function_body_length
        prompt: String,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) {
        self.state = .generating
        
        // Log the most important parameters of the LLM
        Self.logger.debug("n_length = \(self.parameters.maxOutputLength, privacy: .public), n_ctx = \(self.contextParameters.contextWindowSize, privacy: .public), n_batch = \(self.contextParameters.batchSize, privacy: .public), n_kv_req = \(self.parameters.maxOutputLength, privacy: .public)")
        
        // Allocate new model context, if not already present
        if self.context == nil {
            guard let context = llama_new_context_with_model(model, self.contextParameters.llamaCppRepresentation) else {
                Self.logger.error("Failed to initialize context")
                continuation.finish(throwing: LLMError.generationError)
                return
            }
            self.context = context
        }

        // Check if the maximal output generation length is smaller or equals to the context window size.
        guard self.parameters.maxOutputLength <= self.contextParameters.contextWindowSize else {
            Self.logger.error("Error: n_kv_req \(self.parameters.maxOutputLength, privacy: .public) > n_ctx, the required KV cache size is not big enough")
            continuation.finish(throwing: LLMError.generationError)
            return
        }
        
        let tokens = tokenize(prompt)
        
        // Check if the input token count is smaller than the context window size decremented by 4 (space for end tokens).
        guard tokens.count <= self.contextParameters.contextWindowSize - 4 else {
            Self.logger.error("""
            Input prompt is too long with \(tokens.count, privacy: .public) tokens for the configured
            context window size of \(self.contextParameters.contextWindowSize, privacy: .public) tokens.
            """)
            continuation.finish(throwing: LLMError.generationError)
            return
        }
        
        var batch = llama_batch_init(Int32(tokens.count), 0, 1)
        defer {
            llama_batch_free(batch)
        }
        
        // Evaluate the initial prompt
        for (tokenIndex, token) in tokens.enumerated() {
            llama_batch_add(&batch, token, Int32(tokenIndex), SpeziLLMLocalHelpers.getLlamaSeqIdVector(), false)
        }
        // llama_decode will output logits only for the last token of the prompt
        batch.logits[Int(batch.n_tokens) - 1] = 1
        
        if llama_decode(self.context, batch) != 0 {
            Self.logger.error("Initial decoding of the input prompt failed.")
            continuation.finish(throwing: LLMError.generationError)
            return
        }
        
        // Batch already includes tokens from the input prompt
        var batchTokenIndex = batch.n_tokens
        var decodedTokens = 0

        // Calculate the token generation rate
        let startTime = Date()
        
        while batchTokenIndex <= self.parameters.maxOutputLength {
            let nVocab = llama_n_vocab(model)
            let logits = llama_get_logits_ith(self.context, batch.n_tokens - 1)
            
            var candidates: [llama_token_data] = .init(repeating: llama_token_data(), count: Int(nVocab))
            
            for tokenId in 0 ..< nVocab {
                candidates.append(llama_token_data(id: tokenId, logit: logits?[Int(tokenId)] ?? 0, p: 0.0))
            }
            
            var candidatesP: llama_token_data_array = .init(
                data: candidates.withUnsafeMutableBytes { $0.baseAddress?.assumingMemoryBound(to: llama_token_data.self) }, // &candidates
                size: candidates.count,
                sorted: false
            )
            
            // Sample via the temperature method
            let minKeep = Int(max(1, self.samplingParameters.outputProbabilities))
            llama_sample_top_k(self.context, &candidatesP, self.samplingParameters.topK, minKeep)
            llama_sample_tail_free(self.context, &candidatesP, self.samplingParameters.tfs, minKeep)
            llama_sample_typical(self.context, &candidatesP, self.samplingParameters.typicalP, minKeep)
            llama_sample_top_p(self.context, &candidatesP, self.samplingParameters.topP, minKeep)
            llama_sample_min_p(self.context, &candidatesP, self.samplingParameters.minP, minKeep)
            llama_sample_temp(self.context, &candidatesP, self.samplingParameters.temperature)
            let nextTokenId = llama_sample_token(self.context, &candidatesP)
            
            if nextTokenId == llama_token_eos(self.model) || batchTokenIndex == self.parameters.maxOutputLength {
                self.generatedText.append(self.EOS)
                continuation.finish()
                self.state = .ready
                return
            }
            
            let nextStringPiece = String(llama_token_to_piece(context, nextTokenId))
            continuation.yield(nextStringPiece)
            self.generatedText.append(nextStringPiece)
            
            // Prepare the next batch
            llama_batch_clear(&batch)
            
            // Push generated output token for the next evaluation round
            llama_batch_add(&batch, nextTokenId, batchTokenIndex, SpeziLLMLocalHelpers.getLlamaSeqIdVector(), true)
            
            decodedTokens += 1
            batchTokenIndex += 1
            
            // Evaluate the current batch with the transformer model
            let decodeOutput = llama_decode(self.context, batch)
            if decodeOutput != 0 {      // = 0 Success, > 0 Warning, < 0 Error
                Self.logger.error("Decoding of generated output failed. Output: \(decodeOutput, privacy: .public)")
                self.state = .error(error: .generationError)
                continuation.finish(throwing: LLMError.generationError)
                return
            }
        }
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        
        Self.logger.debug("Decoded \(decodedTokens, privacy: .public) tokens in \(String(format: "%.2f", elapsedTime), privacy: .public) s, speed: \(String(format: "%.2f", Double(decodedTokens) / elapsedTime), privacy: .public)) t/s")

        llama_print_timings(self.context)
         
        continuation.finish()
        self.state = .ready
    }
}
