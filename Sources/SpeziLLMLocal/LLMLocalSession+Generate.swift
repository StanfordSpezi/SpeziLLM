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
        
        let modelConfiguration = self.schema.configuration
        
        guard let formattedChat = try? await schema.formatChat(self.context) else {
            Self.logger.error("SpeziLLMLocal: Failed to format chat with given context")
            await finishGenerationWithError(LLMLocalError.illegalContext, on: continuation)
            return
        }
        
        let promptTokens = await modelContainer.perform { _, tokenizer in
            tokenizer.encode(text: formattedChat)
        }
        
        MLXRandom.seed(self.schema.contextParameters.seed ?? UInt64(Date.timeIntervalSinceReferenceDate * 1000))
        
        let extraEOSTokens = modelConfiguration.extraEOSTokens
        
        guard await !checkCancellation(on: continuation) else {
            return
        }
        
        let parameters: GenerateParameters = .init(
            temperature: schema.samplingParameters.temperature,
            topP: schema.samplingParameters.topP,
            repetitionPenalty: schema.samplingParameters.penaltyRepeat,
            repetitionContextSize: schema.samplingParameters.repetitionContextSize
        )
        
        let (result, tokenizer) = await modelContainer.perform { model, tokenizer in
            let result = MLXLLM.generate(
                promptTokens: promptTokens,
                parameters: parameters,
                model: model,
                tokenizer: tokenizer,
                extraEOSTokens: extraEOSTokens
            ) { tokens in
                if Task.isCancelled {
                    return .stop
                }
                
                if tokens.count >= self.schema.parameters.maxOutputLength {
                    Self.logger.debug("SpeziLLMLocal: Max output length exceeded.")
                    continuation.finish()
                    Task { @MainActor in
                        self.state = .ready
                    }
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
            
            return (result, tokenizer)
        }
        
        Self.logger.debug(
            """
            SpeziLLMLocal:
            Prompt Tokens per second: \(result.promptTokensPerSecond, privacy: .public)
            Generation tokens per second: \(result.tokensPerSecond, privacy: .public)
            """
        )
        
        await MainActor.run {
            if schema.injectIntoContext {
                // Yielding every Nth token may result in missing the final tokens.
                let reaminingTokens = result.tokens.count % schema.parameters.displayEveryNTokens
                let lastTokens = Array(result.tokens.suffix(reaminingTokens))
                let text = tokenizer.decode(tokens: lastTokens)
                continuation.yield(text)
            }
            
            context.append(assistantOutput: result.output, complete: true)
            context.completeAssistantStreaming()
            continuation.finish()
            state = .ready
        }
    }
}
