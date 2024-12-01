//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import MLX
import MLXLLM
import MLXRandom
import os
import SpeziChat
import SpeziLLM


extension LLMLocalSession {
    // swiftlint:disable:next identifier_name function_body_length
    internal func _generate(continuation: AsyncThrowingStream<String, any Error>.Continuation) async {
        guard let modelContainer = await self.modelContainer else {
            Self.logger.error("SpeziLLMLocal: Failed to load `modelContainer`")
            await finishGenerationWithError(LLMLocalError.modelNotFound, on: continuation)
            return
        }
        
        let messages = if await !self.customContext.isEmpty {
            await self.customContext
        } else {
            await self.context.formatForTransformersChat()
        }
        
        guard let promptTokens = try? await modelContainer.perform({ _, tokenizer in
            if let chatTempalte = self.schema.parameters.chatTemplate {
               return try tokenizer.applyChatTemplate(messages: messages, chatTemplate: chatTempalte)
            } else {
                return try tokenizer.applyChatTemplate(messages: messages)
            }
        }) else {
            Self.logger.error("SpeziLLMLocal: Failed to format chat with given context")
            await finishGenerationWithError(LLMLocalError.illegalContext, on: continuation)
            return
        }
        
        MLXRandom.seed(self.schema.contextParameters.seed ?? UInt64(Date.timeIntervalSinceReferenceDate * 1000))
        
        guard await !checkCancellation(on: continuation) else {
            return
        }
        
        let parameters: GenerateParameters = .init(
            temperature: schema.samplingParameters.temperature,
            topP: schema.samplingParameters.topP,
            repetitionPenalty: schema.samplingParameters.penaltyRepeat,
            repetitionContextSize: schema.samplingParameters.repetitionContextSize
        )
        
        let result = await modelContainer.perform { model, tokenizer in
            let result = MLXLLM.generate(
                promptTokens: promptTokens,
                parameters: parameters,
                model: model,
                tokenizer: tokenizer,
                extraEOSTokens: schema.parameters.extraEOSTokens
            ) { tokens in
                if Task.isCancelled {
                    return .stop
                }
                
                if tokens.count >= self.schema.parameters.maxOutputLength {
                    Self.logger.debug("SpeziLLMLocal: Max output length exceeded.")
                    return .stop
                }
                
                if schema.injectIntoContext && tokens.count.isMultiple(of: schema.parameters.displayEveryNTokens) {
                    let lastTokens = Array(tokens.suffix(schema.parameters.displayEveryNTokens))
                    let text = tokenizer.decode(tokens: lastTokens)
                    
                    Self.logger.debug("SpeziLLMLocal: Yielded token: \(text, privacy: .public)")
                    continuation.yield(text)
                }
                
                return .more
            }
            
            if schema.injectIntoContext {
                // Yielding every Nth token may result in missing the final tokens.
                let reaminingTokens = result.tokens.count % schema.parameters.displayEveryNTokens
                let lastTokens = Array(result.tokens.suffix(reaminingTokens))
                let text = tokenizer.decode(tokens: lastTokens)
                continuation.yield(text)
            }
            
            return result
        }
        
        Self.logger.debug(
            """
            SpeziLLMLocal:
            Prompt Tokens per second: \(result.promptTokensPerSecond, privacy: .public)
            Generation tokens per second: \(result.tokensPerSecond, privacy: .public)
            """
        )
        
        await MainActor.run {
            context.append(assistantOutput: result.output, complete: true)
            context.completeAssistantStreaming()
            
            if !schema.injectIntoContext {
                continuation.yield(result.output)
            }
            continuation.finish()
            state = .ready
        }
    }
}
