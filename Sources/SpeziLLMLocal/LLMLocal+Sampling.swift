//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import llama


extension LLMLocal {
    /// Based on the current state of the context, sample the to be inferred output via the temperature method
    ///
    /// - Parameters:
    ///     - batchSize: The current size of the `llama_batch`
    /// - Returns: A sampled `LLMLocalToken`
    func sample(batchSize: Int32) -> LLMLocalToken {
        let nVocab = llama_n_vocab(model)
        let logits = llama_get_logits_ith(self.modelContext, batchSize - 1)
        
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
        llama_sample_top_k(self.modelContext, &candidatesP, self.samplingParameters.topK, minKeep)
        llama_sample_tail_free(self.modelContext, &candidatesP, self.samplingParameters.tfs, minKeep)
        llama_sample_typical(self.modelContext, &candidatesP, self.samplingParameters.typicalP, minKeep)
        llama_sample_top_p(self.modelContext, &candidatesP, self.samplingParameters.topP, minKeep)
        llama_sample_min_p(self.modelContext, &candidatesP, self.samplingParameters.minP, minKeep)
        llama_sample_temp(self.modelContext, &candidatesP, self.samplingParameters.temperature)
        
        return llama_sample_token(self.modelContext, &candidatesP)
    }
}
