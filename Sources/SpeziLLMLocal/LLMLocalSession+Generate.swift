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
import MLXLMCommon
import MLXRandom
import os
import SpeziChat
import SpeziLLM


extension LLMLocalSession {
    // swiftlint:disable:next identifier_name
    internal func _generate(continuation: AsyncThrowingStream<String, any Error>.Continuation) async {
#if targetEnvironment(simulator)
        await _mockGenerate(continuation: continuation)
        return
#endif
        
        guard let modelContainer = await self.modelContainer else {
            Self.logger.error("SpeziLLMLocal: Failed to load `modelContainer`")
            await finishGenerationWithError(LLMLocalError.modelNotFound, on: continuation)
            return
        }
        
        let messages = if await !self.customContext.isEmpty {
            await self.customContext
        } else {
            await self.context.formattedChat
        }
        
        guard let modelInput: LMInput = try? await prepareModelInput(messages: messages, modelContainer: modelContainer) else {
            Self.logger.error("SpeziLLMLocal: Failed to format chat with given context")
            await finishGenerationWithError(LLMLocalError.illegalContext, on: continuation)
            return
        }
        
        MLXRandom.seed(self.schema.parameters.seed ?? UInt64(Date.timeIntervalSinceReferenceDate * 1000))
        
        guard await !checkCancellation(on: continuation) else {
            return
        }
        
        let parameters: GenerateParameters = .init(
            temperature: schema.samplingParameters.temperature,
            topP: schema.samplingParameters.topP,
            repetitionPenalty: schema.samplingParameters.penaltyRepeat,
            repetitionContextSize: schema.samplingParameters.repetitionContextSize
        )
        
        do {
            let result = try await modelContainer.perform { modelContext in
                let result = try MLXLMCommon.generate(
                    input: modelInput,
                    parameters: parameters,
                    context: modelContext
                ) { tokens in
                    processTokens(tokens, modelContext: modelContext, continuation: continuation)
                }
                
                // Yielding every Nth token may result in missing the final tokens.
                processRemainingTokens(result: result, modelContext: modelContext, continuation: continuation)
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
                continuation.finish()
                state = .ready
            }
        } catch {
            Self.logger.error("SpeziLLMLocal: Generation ended with error: \(error)")
            await finishGenerationWithError(LLMLocalError.generationError, on: continuation)
            return
        }
    }
    
    private func prepareModelInput(messages: [[String: String]], modelContainer: ModelContainer) async throws -> LMInput {
        try await modelContainer.perform { modelContext in
            if let chatTemplate = self.schema.parameters.chatTemplate {
                let tokens = try modelContext.tokenizer.applyChatTemplate(messages: messages, chatTemplate: chatTemplate)
                return LMInput(text: .init(tokens: MLXArray(tokens)))
            } else {
                return try await modelContext.processor.prepare(input: .init(messages: messages))
            }
        }
    }
    
    private func processTokens(
        _ tokens: [Int],
        modelContext: ModelContext,
        continuation: AsyncThrowingStream<String, any Error>.Continuation
    ) -> GenerateDisposition {
        if Task.isCancelled {
            return .stop
        }
        
        if tokens.count >= self.schema.parameters.maxOutputLength {
            Self.logger.debug("SpeziLLMLocal: Max output length exceeded.")
            return .stop
        }
        
        if tokens.count.isMultiple(of: schema.parameters.displayEveryNTokens) {
            let lastTokens = Array(tokens.suffix(schema.parameters.displayEveryNTokens))
            let text = modelContext.tokenizer.decode(tokens: lastTokens)
            
            Self.logger.debug("SpeziLLMLocal: Yielded token: \(text, privacy: .public)")
            continuation.yield(text)
            
            if schema.injectIntoContext {
                Task { @MainActor in
                    context.append(assistantOutput: text)
                }
            }
        }
        
        return .more
    }
    
    private func processRemainingTokens(
        result: GenerateResult,
        modelContext: ModelContext,
        continuation: AsyncThrowingStream<String, any Error>.Continuation
    ) {
        // Yielding every Nth token may result in missing the final tokens.
        let remainingTokens = result.tokens.count % schema.parameters.displayEveryNTokens
        let lastTokens = Array(result.tokens.suffix(remainingTokens))
        let text = modelContext.tokenizer.decode(tokens: lastTokens)
        continuation.yield(text)
        
        if schema.injectIntoContext {
            Task { @MainActor in
                context.append(assistantOutput: text)
                context.completeAssistantStreaming()
            }
        }
    }
    
    private func _mockGenerate(continuation: AsyncThrowingStream<String, any Error>.Continuation) async {
        let tokens = [
            "Mock ", "Message ", "from ", "SpeziLLM! ",
            "**Using SpeziLLMLocal only works on physical devices.**",
            "\n\n",
            String(localized: "LLM_MLX_NOT_SUPPORTED_WORKAROUND", bundle: .module)
        ]
        
        for token in tokens {
            try? await Task.sleep(for: .seconds(1))
            guard await !checkCancellation(on: continuation) else {
                return
            }
            continuation.yield(token)
        }
        
        continuation.finish()
        await MainActor.run {
            context.completeAssistantStreaming()
            self.state = .ready
        }
    }
}
