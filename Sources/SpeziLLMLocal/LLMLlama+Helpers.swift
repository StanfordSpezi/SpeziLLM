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
        let tokens = UnsafeMutablePointer<llama_token>.allocate(capacity: nTokens)
        let tokenCount = llama_tokenize(self.model, text, Int32(text.count), tokens, Int32(nTokens), self.parameters.addBosToken, false)
        var swiftTokens: [llama_token] = []
        for tokenIndex in 0 ..< tokenCount {
            swiftTokens.append(tokens[Int(tokenIndex)])
        }
        tokens.deallocate()
        return swiftTokens
    }
    
    /// Converts a `LLMLlamaToken` to the textual `String` based on the model's dictionary.
    /// This is a required tasks as LLMs internally processes tokens.
    ///
    /// - Parameters:
    ///   - token: The `LLMLlamaToken` that should be converted.
    ///   - buffer: A buffer helping with the conversion.
    ///
    /// - Returns: The textual `String` of the `LLMLlamaToken`.
    func tokenToPiece(token: LLMLlamaToken, buffer: inout [CChar]) -> String? {
        var result = [CChar](repeating: 0, count: 8)
        let nTokens = llama_token_to_piece(model, token, &result, Int32(result.count))
        if nTokens < 0 {
            if result.count >= -Int(nTokens) {
                result.removeLast(-Int(nTokens))
            } else {
                result.removeAll()
            }
            let check = llama_token_to_piece(
                model,
                token,
                &result,
                Int32(result.count)
            )
            assert(check == nTokens)
        } else {
            result.removeLast(result.count - Int(nTokens))
        }
        
        guard buffer.isEmpty,
              let utfString = String(cString: result + [0], encoding: .utf8) else {
            buffer.append(contentsOf: result)
            let data = Data(buffer.map { UInt8(bitPattern: $0) })
            /// 4 bytes is the max length of a utf8 character so if we're here we need to reset the buffer
            if buffer.count >= 4 {
                buffer = []
            }
            guard let bufferString = String(data: data, encoding: .utf8) else {
                return nil
            }
            buffer = []
            return bufferString
        }
        
        return utfString
    }
}
