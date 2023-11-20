//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import llama


/// Extension of ``LLMLlama`` handling the text tokenization.
extension LLMLlama {
    /// Converts a textual `String` to the individual `LLMLlamaToken`'s based on the model's dictionary.
    /// This is a required tasks as LLMs internally processes tokens.
    ///
    /// - Parameters:
    ///   - text: The input `String` that should be tokenized.
    ///   
    /// - Returns: The tokenized `String` as `LLMLlamaToken`'s.
    func tokenize(text: String) -> [LLMLlamaToken] {
        let nTokens = text.count + (self.parameters.addBosToken ? 1 : 0)
        let cTokens = UnsafeMutablePointer<llama_token>.allocate(capacity: nTokens)
        
        let tokenCount = llama_tokenize(self.model, text, Int32(text.count), cTokens, Int32(nTokens), self.parameters.addBosToken, false)
        
        var tokens: [llama_token] = []
        for tokenIndex in 0 ..< tokenCount {
            tokens.append(cTokens[Int(tokenIndex)])
        }
        cTokens.deallocate()
        return tokens
    }
}
