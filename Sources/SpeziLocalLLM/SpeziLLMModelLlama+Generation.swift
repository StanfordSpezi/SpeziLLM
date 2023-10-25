//
// This source file is part of the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
import llama


extension SpeziLLMModelLlama {
    typealias LlamaToken = llama_token
    
    
    // swiftlint:disable:next identifier_name function_body_length
    func _generate(
        prompt: String,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) {
        self.state = .inferring
        
        let tokens = tokenize(text: prompt)
        // TODO: Get rid of a fixed size n_length (output length) -> needs to be dynamic!
        let nKVReq = UInt32(tokens.count) + UInt32((self.modelParameters.nLength - Int(tokens.count)))
        
        let context = llama_new_context_with_model(model, self.contextParameters.wrapped)
        guard context != nil else {
            print("Failed to initialize context")
            continuation.finish(throwing: SpeziLLMError.failedToEval)
            return
        }
        defer {
            llama_free(context)
        }

        let nCtx = llama_n_ctx(context)
        
        print("\n_length = \(self.modelParameters.nLength), n_ctx = \(nCtx), n_batch = \(self.contextParameters.nBatch), n_kv_req = \(nKVReq)\n")

        if nKVReq > nCtx {
            print("error: n_kv_req (%d) > n_ctx, the required KV cache size is not big enough\n", nKVReq)
            continuation.finish(throwing: SpeziLLMError.failedToEval)
            return
        }
        
        var buffer: [CChar] = []
        for id: LlamaToken in tokens {
            print(token_to_piece(token: id, buffer: &buffer) ?? "", terminator: "")
        }
        
        print("\n")
        
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
            print("llama_decode() failed")
            continuation.finish(throwing: SpeziLLMError.failedToEval)
            return
        }
        
        var nCur = batch.n_tokens
        var nDecode = 0
        
        var streamBuffer: [CChar] = .init()

        let startTime = ggml_time_us()
        
        while nCur <= self.modelParameters.nLength {
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
            
            
            let topK: Int32 = 40
            let topP: Float = 0.9
            let temp: Float = 0.7
            
            // TODO: Can one sample multiple times?!
            llama_sample_top_k(context, &candidatesP, topK, 1)
            llama_sample_top_p(context, &candidatesP, topP, 1)
            llama_sample_temp(context, &candidatesP, temp)
            
            let nextTokenId = llama_sample_token(context, &candidatesP)
            // Greedy sampeling
            // let nextTokenId = llama_sample_token_greedy(context, &candidates_p)
            
            if nextTokenId == llama_token_eos(self.model) || nCur == self.modelParameters.nLength {
                print("\n")
                self.state = .ready
                continuation.finish()
                return
            }
            
            let nextStringPiece = token_to_piece(token: nextTokenId, buffer: &streamBuffer) ?? ""
            print(nextStringPiece, terminator: "")
            continuation.yield(nextStringPiece)
            
            batch.n_tokens = 0
            
            // push this new token for next evaluation
            batch.token[Int(batch.n_tokens)] = nextTokenId
            batch.pos[Int(batch.n_tokens)] = nCur
            batch.n_seq_id[Int(batch.n_tokens)] = 1
            batch.seq_id[Int(batch.n_tokens)]?[0] = 0
            batch.logits[Int(batch.n_tokens)] = 1
            
            batch.n_tokens += 1
            
            nDecode += 1
            
            nCur += 1
            
            // evaluate the current batch with the transformer model
            let decodeOutput = llama_decode(context, batch)
            if decodeOutput != 0 {      // = 0 Success, > 0 Warning, < 0 Error
                print("llama_decode() failed: Return \(decodeOutput)")
                self.state = .error(error: .failedToEval)
                continuation.finish(throwing: SpeziLLMError.generationError)
                return
            }
        }
        
        let endTime = ggml_time_us()
        
        print("\n")
        print("decoded \(nDecode) tokens in \(String(format: "%.2f", Double(endTime - startTime) / 1_000_000.0)) s, speed: \(String(format: "%.2f", Double(nDecode) / (Double(endTime - startTime) / 1_000_000.0))) t/s\n")

        llama_print_timings(context)
        
        self.state = .ready
        continuation.finish()
    }
}