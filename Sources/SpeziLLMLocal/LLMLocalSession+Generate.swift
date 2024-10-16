//
//  LLMLocalSession+Generate.swift
//  SpeziLLM
//
//  Created by Leon Nissen on 10/15/24.
//
import Foundation
import os
import SpeziChat
import SpeziLLM
import MLXLLM
import MLX
import MLXRandom

extension LLMLocalSession {
    func _generate(continuation: AsyncThrowingStream<String, any Error>.Continuation) async {
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
        
        let prompt = modelConfiguration.prepare(prompt: formattedChat)
        let promptTokens = await modelContainer.perform { _, tokenizer in
            tokenizer.encode(text: prompt)
        }
        
        // each time you generate you will get something new
        MLXRandom.seed(UInt64(Date.timeIntervalSinceReferenceDate * 1000))
        
        let extraEOSTokens = modelConfiguration.extraEOSTokens
        
        guard await !checkCancellation(on: continuation) else {
            return
        }
        
        let (result, tokenizer) = await modelContainer.perform { model, tokenizer in
            // Execute the inference
            let result = MLXLLM.generate(
                promptTokens: promptTokens,
                parameters: self.schema.generateParameters,
                model: model,
                tokenizer: tokenizer,
                extraEOSTokens: extraEOSTokens
            ) { tokens in
                if Task.isCancelled {
                    return .stop
                }
                
                if tokens.count >= self.schema.maxTokens {
                    continuation.finish()
                    Task { @MainActor in
                        self.state = .ready
                    }
                    return .stop
                }
                
                if schema.injectIntoContext && tokens.count % schema.displayEveryNTokens == 0 {
                    let lastTokens = Array(tokens.suffix(schema.displayEveryNTokens))
                    let text = " " + tokenizer.decode(tokens: lastTokens)
                    continuation.yield(text)
                }
                
                return .more
            }
            
            return (result, tokenizer)
        }
        
        await MainActor.run {
            if schema.injectIntoContext {
                // Yielding every Nth token may result in missing the final tokens.
                let reaminingTokens = result.tokens.count % schema.displayEveryNTokens
                let lastTokens = Array(result.tokens.suffix(reaminingTokens))
                let text = " " + tokenizer.decode(tokens: lastTokens)
                continuation.yield(text)
                context.completeAssistantStreaming()
            } else {
                context.append(assistantOutput: result.output, complete: true)
            }
            state = .ready
        }
    }
}
