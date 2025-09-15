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
    
    func _generateForBenchmark(
        with continuation: AsyncThrowingStream<String, any Error>.Continuation
    ) async -> GenerateResult? {
        if Task.isCancelled {
            Self.logger.warning("SpeziLLMLocal: Generation cancelled by the user.")
            return nil
        }
        
        await MainActor.run {
            self.state = .generating
        }
        
        guard let modelContainer = await self.modelContainer else {
            return nil
        }
        
        let messages = if await !self.customContext.isEmpty {
            await self.customContext
        } else {
            await self.context.formattedChat
        }
        
        guard let modelInput: LMInput = try? await prepareModelInput(messages: messages, modelContainer: modelContainer) else {
            await handleError("Failed to format chat with given context", error: .illegalContext, continuation: continuation)
            return nil
        }
        
        if Task.isCancelled {
            Self.logger.warning("SpeziLLMLocal: Generation cancelled by the user.")
            await MainActor.run {
                self.state = .ready
            }
            return nil
        }
        
        MLXRandom.seed(self.schema.parameters.seed ?? UInt64(Date.timeIntervalSinceReferenceDate * 1000))
        
        do {
            let result = try await modelContainer.perform { modelContext in
                let result = try MLXLMCommon.generate(
                    input: modelInput,
                    parameters: generationParameters,
                    context: modelContext
                ) { tokens in
                    if Task.isCancelled {
                        Self.logger.warning("SpeziLLMLocal: Generation cancelled by the user.")
                        return .stop
                    }
                    
                    if tokens.count >= self.schema.parameters.maxOutputLength {
                        Self.logger.debug("SpeziLLMLocal: Max output length exceeded.")
                        return .stop
                    }
                    
                    return .more
                }
                return result
            }
            
            await MainActor.run {
                continuation.finish()
                self.state = .ready
            }
            
            return result
        } catch {
            await handleError("Generation ended with error: \(error)", error: .generationError, continuation: continuation)
            return nil
        }
    }
    
    
    
    // swiftlint:disable:next identifier_name function_body_length
    func _generate(
        with continuationObserver: ContinuationObserver<String, any Error>
    ) async {
        // Check if the generation has been cancelled
        if continuationObserver.isCancelled {
            Self.logger.warning("SpeziLLMLocal: Generation cancelled by the user.")
            return
        }
        
        await MainActor.run {
            self.state = .generating
        }
        
#if targetEnvironment(simulator)
        await _mockGenerate(continuationObserver: continuationObserver)
        return
#else
        guard let modelContainer = await self.modelContainer else {
            await handleError("Failed to load `modelContainer`", error: .modelNotFound, continuation: continuationObserver.continuation)
            return
        }
        
        let messages = if await !self.customContext.isEmpty {
            await self.customContext
        } else {
            await self.context.formattedChat
        }
        
        guard let modelInput: LMInput = try? await prepareModelInput(messages: messages, modelContainer: modelContainer) else {
            await handleError("Failed to format chat with given context", error: .illegalContext, continuation: continuationObserver.continuation)
            return
        }
        
        if continuationObserver.isCancelled {
            Self.logger.warning("SpeziLLMLocal: Generation cancelled by the user.")
            await MainActor.run {
                self.state = .ready
            }
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
                    self.processTokens(
                        tokens,
                        modelContext: modelContext,
                        continuationObserver: continuationObserver
                    )
                }
                
                self.processRemainingTokens(
                    result: result,
                    modelContext: modelContext,
                    continuation: continuationObserver.continuation
                )
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
                continuationObserver.continuation.finish()
                self.state = .ready
            }
        } catch {
            await handleError("Generation ended with error: \(error)", error: .generationError, continuation: continuationObserver.continuation)
            return
        }
#endif
    }
    
    private func prepareModelInput(
        messages: [[String: String]],
        modelContainer: ModelContainer
    ) async throws -> LMInput {
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
        continuationObserver: ContinuationObserver<String, any Error>
    ) -> GenerateDisposition {
        // Check if the generation has been cancelled
        if continuationObserver.isCancelled {
            Self.logger.warning("SpeziLLMLocal: Generation cancelled by the user.")
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
            continuationObserver.continuation.yield(text)
            
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
    
    private func _mockGenerate(continuationObserver: ContinuationObserver<String, any Error>) async {
        let tokens = [
            "Mock ", "Message ", "from ", "SpeziLLM! ",
            "**Using SpeziLLMLocal only works on physical devices.**",
            "\n\n",
            String(localized: "LLM_MLX_NOT_SUPPORTED_WORKAROUND", bundle: .module)
        ]
        
        for token in tokens {
            try? await Task.sleep(for: .seconds(1))
            if continuationObserver.isCancelled {
                Self.logger.error("SpeziLLMLocal: Generation cancelled by the user.")
                break
            }
            
            continuationObserver.continuation.yield(token)
        }
        
        continuationObserver.continuation.finish()
        await MainActor.run {
            self.context.completeAssistantStreaming()
            self.state = .ready
        }
    }
}
