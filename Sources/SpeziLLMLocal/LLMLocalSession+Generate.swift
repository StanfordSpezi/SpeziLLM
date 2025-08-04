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
@preconcurrency import MLXLMCommon
import MLXRandom
import os
import SpeziChat
import SpeziLLM


extension LLMLocalSession {
    private var generationParameters: GenerateParameters {
        .init(
            temperature: schema.samplingParameters.temperature,
            topP: schema.samplingParameters.topP,
            repetitionPenalty: schema.samplingParameters.penaltyRepeat,
            repetitionContextSize: schema.samplingParameters.repetitionContextSize
        )
    }
    
    // swiftlint:disable:next identifier_name
    internal func _generate(continuation: AsyncThrowingStream<String, any Error>.Continuation) async {
#if targetEnvironment(simulator)
        await _mockGenerate(continuation: continuation)
        return
#else
        guard let modelContainer = await self.modelContainer else {
            await handleError("Failed to load `modelContainer`", error: .modelNotFound, continuation: continuation)
            return
        }
        
        let messages = if await !self.customContext.isEmpty {
            await self.customContext
        } else {
            await self.context.formattedChat
        }
        
        guard let modelInput: LMInput = try? await prepareModelInput(messages: messages, modelContainer: modelContainer) else {
            await handleError("Failed to format chat with given context", error: .illegalContext, continuation: continuation)
            return
        }
        
        MLXRandom.seed(self.schema.parameters.seed ?? UInt64(Date.timeIntervalSinceReferenceDate * 1000))
        
        do {
            let result = try await modelContainer.perform { modelContext in
                let result = try MLXLMCommon.generate(
                    input: modelInput,
                    parameters: generationParameters,
                    context: modelContext
                ) { tokens in
                    processTokens(tokens, modelContext: modelContext, continuation: continuation)
                }
                
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
                self.state = .ready
            }
        } catch {
            await handleError("Generation ended with error: \(error)", error: .generationError, continuation: continuation)
            return
        }
#endif
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
            if case .terminated = continuation.yield(text) {
                Self.logger.error("SpeziLLMLocal: Generation cancelled by the user.")

                // indicate that no further tokens should be generated, no other cleanup needed
                return .stop
            }

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
    
    private func handleError(_ message: String, error: LLMLocalError, continuation: AsyncThrowingStream<String, any Error>.Continuation) async {
        Self.logger.error("SpeziLLMLocal: \(message)")
        await finishGenerationWithError(error, on: continuation)
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

            if case .terminated = continuation.yield(token) {
                Self.logger.error("SpeziLLMLocal: Generation cancelled by the user.")
                break
            }
        }
        
        continuation.finish()
        await MainActor.run {
            context.completeAssistantStreaming()
            self.state = .ready
        }
    }
}
