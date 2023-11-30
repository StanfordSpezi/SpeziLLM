//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import CxxStdlib
import Foundation
import llama
import SpeziLLMLocalHelpers


/// Extension of ``LLMLlama`` handling the text tokenization.
extension LLMLlama {
    /// BOS token of the LLM, used at the start of each prompt passage.
    var BOS: String {
        "<s>"
    }
    
    /// EOS token of the LLM, used at the end of each prompt passage.
    var EOS: String {
        "</s>"
    }
    
    /// BOSYS token of the LLM, used at the start of the system prompt.
    var BOSYS: String {
        "<<SYS>>"
    }
    
    /// EOSYS token of the LLM, used at the end of the system prompt.
    var EOSYS: String {
        "<</SYS>>"
    }
    
    /// BOINST token of the LLM, used at the start of the instruction part of the prompt.
    var BOINST: String {
        "[INST]"
    }
    
    /// EOINST token of the LLM, used at the end of the instruction part of the prompt.
    var EOINST: String {
        "[/INST]"
    }
    
    
    /// Converts a textual `String` to the individual `LLMLlamaToken`'s based on the model's dictionary.
    /// This is a required tasks as LLMs internally processes tokens.
    ///
    /// - Parameters:
    ///   - toBeTokenizedText: The input `String` that should be tokenized.
    ///
    /// - Returns: The tokenized `String` as `LLMLlamaToken`'s.
    func tokenize(_ toBeTokenizedText: String) -> [LLMLlamaToken] {
        let formattedPrompt = buildPrompt(with: toBeTokenizedText)
        if self.generatedText.isEmpty {
            self.generatedText = formattedPrompt
        } else {
            self.generatedText.append(formattedPrompt)
        }
        
        var tokens: [LLMLlamaToken] = .init(
            llama_tokenize_with_context(self.context, std.string(self.generatedText), self.parameters.addBosToken, true)
        )
        
        // Truncate tokens if there wouldn't be enough context size for the generated output
        if tokens.count > Int(self.contextParameters.contextWindowSize) - self.parameters.maxOutputLength {
            tokens = Array(tokens.suffix(Int(self.contextParameters.contextWindowSize) - self.parameters.maxOutputLength))
        }
        
        // Output generation shouldn't run without any tokens
        if tokens.isEmpty {
            tokens.append(llama_token_bos(self.model))
            Self.logger.warning("""
            The input prompt didn't map to any tokens, so the prompt was considered empty.
            To mediate this issue, a BOS token was added to the prompt so that the output generation
            doesn't run without any tokens.
            """)
        }
        
        return tokens
    }
    
    /// Converts an array of `LLMLlamaToken`s to an array of tupels of `LLMLlamaToken`s as well as their `String` representation.
    ///
    /// - Parameters:
    ///     - tokens: An array of `LLMLlamaToken`s that should be detokenized.
    /// - Returns: An array of tupels of `LLMLlamaToken`s as well as their `String` representation.
    /// 
    /// - Note: Used only for debug purposes
    func detokenize(tokens: [LLMLlamaToken]) -> [(LLMLlamaToken, String)] {
        tokens.reduce(into: [(LLMLlamaToken, String)]()) { partialResult, token in
            partialResult.append((token, String(llama_token_to_piece(self.context, token))))
        }
    }
    
    /// Based on the current state of the context, sample the to be inferred output via the temperature method
    ///
    /// - Parameters:
    ///     - batchSize: The current size of the `llama_batch`
    /// - Returns: A sampled `LLMLLamaToken`
    func sample(batchSize: Int32) -> LLMLlamaToken {
        let nVocab = llama_n_vocab(model)
        let logits = llama_get_logits_ith(self.context, batchSize - 1)
        
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
        
        return llama_sample_token(self.context, &candidatesP)
    }
    
    /// Build a typical Llama2 prompt format out of the user's input including the system prompt and all necessary instruction tokens.
    ///
    /// The typical format of an Llama2 prompt looks like:
    /// """
    /// <s>[INST] <<SYS>>
    /// {your_system_message}
    /// <</SYS>>
    ///
    /// {user_message_1} [/INST] {model_reply_1}</s><s>[INST] {user_message_2} [/INST]
    /// """
    ///
    /// - Parameters:
    ///     - userInputString: String-based input prompt of the user.
    /// - Returns: Properly formatted Llama2 prompt including system prompt.
    private func buildPrompt(with userInputString: String) -> String {
        if self.generatedText.isEmpty {
            """
            \(BOS)\(BOINST) \(BOSYS)
            \(self.parameters.systemPrompt)
            \(EOSYS)
            
            \(userInputString) \(EOINST)
            """ + " "   // Add a spacer to the generated output from the model
        } else {
            """
            \(BOS)\(BOINST) \(userInputString) \(EOINST)
            """ + " "   // Add a spacer to the generated output from the model
        }
    }
}
