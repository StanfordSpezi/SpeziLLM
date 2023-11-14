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
    ///   - prompt: The input `String` prompt.
    ///   - continuation: A Swift `AsyncThrowingStream` that streams the generated output.
    func _generate( // swiftlint:disable:this identifier_name function_body_length
        prompt: String,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) {
        self.state = .generating
        
        let tokens = tokenize(text: prompt)
        let nKVReq = UInt32(tokens.count) + UInt32((self.parameters.maxOutputLength - Int(tokens.count)))
        
        let context = llama_new_context_with_model(model, self.contextParameters.getLlamaCppRepresentation())
        guard context != nil else {
            Self.logger.error("Failed to initialize context")
            continuation.finish(throwing: LLMError.generationError)
            return
        }
        defer {
            llama_free(context)
        }

        let nCtx = llama_n_ctx(context)
        
        Self.logger.debug("\n_length = \(self.parameters.maxOutputLength, privacy: .public), n_ctx = \(nCtx, privacy: .public), n_batch = \(self.contextParameters.batchSize, privacy: .public), n_kv_req = \(nKVReq, privacy: .public)\n")

        if nKVReq > nCtx {
            Self.logger.error("Error: n_kv_req \(nKVReq, privacy: .public) > n_ctx, the required KV cache size is not big enough")
            continuation.finish(throwing: LLMError.generationError)
            return
        }
        
        // Convert input prompt tokens back to string
        /*
        var buffer: [CChar] = []
        for id: LLMLlamaToken in tokens {
            self.tokenToPiece(token: id, buffer: &buffer)
        }
         */
        
        var batch = llama_batch_init(Int32(tokens.count), 0, 1)
        defer {
            llama_batch_free(batch)
        }
        
        // evaluate the initial prompt
        batch.n_tokens = Int32(tokens.count)
        
        for (tokenIndex, token) in tokens.enumerated() {
            batch.token[tokenIndex] = token
            batch.pos[tokenIndex] = Int32(tokenIndex)
            batch.n_seq_id[tokenIndex] = 1
            batch.seq_id[tokenIndex]?[0] = 0
            batch.logits[tokenIndex] = 0
        }
        
        // llama_decode will output logits only for the last token of the prompt
        batch.logits[Int(batch.n_tokens) - 1] = 1
        
        if llama_decode(context, batch) != 0 {
            Self.logger.error("llama_decode() failed")
            continuation.finish(throwing: LLMError.generationError)
            return
        }
        
        var nCur = batch.n_tokens
        var decodedTokens = 0
        
        var streamBuffer: [CChar] = .init()

        let startTime = Date()
        
        while nCur <= self.parameters.maxOutputLength {
            let nVocab = llama_n_vocab(model)
            let logits = llama_get_logits_ith(context, batch.n_tokens - 1)
            
            var candidates: [llama_token_data] = .init(repeating: llama_token_data(), count: Int(nVocab))
            
            for tokenId in 0 ..< nVocab {
                candidates.append(llama_token_data(id: tokenId, logit: logits?[Int(tokenId)] ?? 0, p: 0.0))
            }
            
            var candidatesP: llama_token_data_array = .init(
                data: candidates.withUnsafeMutableBytes { $0.baseAddress?.assumingMemoryBound(to: llama_token_data.self) }, // &candidates
                size: candidates.count,
                sorted: false
            )
            
            llama_sample_top_k(context, &candidatesP, self.parameters.topK, 1)
            llama_sample_top_p(context, &candidatesP, self.parameters.topP, 1)
            llama_sample_temp(context, &candidatesP, self.parameters.temperature)
            
            let nextTokenId = llama_sample_token(context, &candidatesP)
            // Greedy sampling
            // let nextTokenId = llama_sample_token_greedy(context, &candidatesP)
            
            if nextTokenId == llama_token_eos(self.model) || nCur == self.parameters.maxOutputLength {
                self.state = .ready
                continuation.finish()
                return
            }
            
            continuation.yield(tokenToPiece(token: nextTokenId, buffer: &streamBuffer) ?? "")
            
            batch.n_tokens = 0
            // push this new token for next evaluation
            batch.token[Int(batch.n_tokens)] = nextTokenId
            batch.pos[Int(batch.n_tokens)] = nCur
            batch.n_seq_id[Int(batch.n_tokens)] = 1
            batch.seq_id[Int(batch.n_tokens)]?[0] = 0
            batch.logits[Int(batch.n_tokens)] = 1
            batch.n_tokens += 1
            
            decodedTokens += 1
            
            nCur += 1
            
            // evaluate the current batch with the transformer model
            let decodeOutput = llama_decode(context, batch)
            if decodeOutput != 0 {      // = 0 Success, > 0 Warning, < 0 Error
                Self.logger.error("llama_decode() failed: Return \(decodeOutput, privacy: .public)")
                self.state = .error(error: .generationError)
                continuation.finish(throwing: LLMError.generationError)
                return
            }
        }
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        
        Self.logger.debug("Decoded \(decodedTokens, privacy: .public) tokens in \(String(format: "%.2f", elapsedTime), privacy: .public) s, speed: \(String(format: "%.2f", Double(decodedTokens) / elapsedTime), privacy: .public)) t/s\n")

        llama_print_timings(context)
        
        self.state = .ready
        continuation.finish()
    }
}
