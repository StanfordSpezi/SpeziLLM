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
    func tokenize(text: String) -> [LlamaToken] {
        let nTokens = text.count + (self.modelParameters.addBos ? 1 : 0)
        let tokens = UnsafeMutablePointer<llama_token>.allocate(capacity: nTokens)
        let tokenCount = llama_tokenize(self.model, text, Int32(text.count), tokens, Int32(nTokens), self.modelParameters.addBos, false)
        var swiftTokens: [llama_token] = []
        for tokenIndex in 0 ..< tokenCount {
            swiftTokens.append(tokens[Int(tokenIndex)])
        }
        tokens.deallocate()
        return swiftTokens
    }
    
    func token_to_piece(token: LlamaToken, buffer: inout [CChar]) -> String? {
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
        if buffer.isEmpty, let utfString = String(cString: result + [0], encoding: .utf8) {
            return utfString
        } else {
            buffer.append(contentsOf: result)
            let data = Data(buffer.map { UInt8(bitPattern: $0) })
            if buffer.count >= 4 { // 4 bytes is the max length of a utf8 character so if we're here we need to reset the buffer
                buffer = []
            }
            guard let bufferString = String(data: data, encoding: .utf8) else {
                return nil
            }
            buffer = []
            return bufferString
        }
    }
}
