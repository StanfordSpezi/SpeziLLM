//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

#if canImport(FoundationModels)
import FoundationModels
#endif
import Foundation
import SpeziChat
import SpeziLLM


extension LLMFoundationModelsSession {
    @discardableResult
    public func generate() async throws -> AsyncThrowingStream<String, any Error> {
        if await self.context.isEmpty {
            if let instructions = self.schema.parameters.instructions {
                await MainActor.run {
                    self.context.append(systemMessage: instructions)
                }
            }
        }

        return try self.platform.queue.submit { continuation in
            let continuationObserver = ContinuationObserver(track: continuation)
            defer {
                continuationObserver.continuation.finish()
            }

            await self.continuationHolder.withContinuationHold(continuation: continuation) {
                if continuationObserver.isCancelled {
                    Self.logger.warning("SpeziLLMFoundationModels: Generation cancelled by the user.")
                    return
                }

                do {
                    try await self.ensureSessionReady()
                } catch {
                    await self.finishGenerationWithError(
                        LLMFoundationModelsError.generationFailed(underlying: String(describing: error)),
                        on: continuation
                    )
                    return
                }

                await self._generate(with: continuationObserver)
            }
        }
    }

    // swiftlint:disable:next function_body_length
    private func _generate(with continuationObserver: ContinuationObserver<String, any Error>) async {
        if continuationObserver.isCancelled {
            Self.logger.warning("SpeziLLMFoundationModels: Generation cancelled by the user.")
            return
        }

        await MainActor.run {
            self.state = .generating
        }

#if canImport(FoundationModels)
        guard #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) else {
            await self.finishGenerationWithError(
                LLMFoundationModelsError.frameworkUnavailable,
                on: continuationObserver.continuation
            )
            return
        }

        let prompt = await self.buildPrompt()
        guard let prompt else {
            await self.finishGenerationWithError(
                LLMFoundationModelsError.missingPrompt,
                on: continuationObserver.continuation
            )
            return
        }

        do {
            let session = try await MainActor.run { try self.resolvedLanguageModelSession() }
            let stream = session.streamResponse(
                to: prompt,
                generating: String.self,
                options: self.schema.parameters.generationOptions
            )

            var fullResponse = ""
            for try await snapshot in stream {
                if continuationObserver.isCancelled {
                    Self.logger.warning("SpeziLLMFoundationModels: Generation cancelled by the user.")
                    break
                }

                let currentText = snapshot.content
                let delta: String
                if currentText.count > fullResponse.count {
                    delta = String(currentText[currentText.index(currentText.startIndex, offsetBy: fullResponse.count)...])
                } else {
                    delta = ""
                }

                if !delta.isEmpty {
                    continuationObserver.continuation.yield(delta)

                    if self.schema.injectIntoContext {
                        await MainActor.run {
                            self.context.append(assistantOutput: delta)
                        }
                    }
                }

                fullResponse = currentText
            }

            if self.schema.injectIntoContext {
                await MainActor.run {
                    self.context.completeAssistantStreaming()
                }
            }

            continuationObserver.continuation.finish()
            await MainActor.run {
                self.state = .ready
            }
        } catch {
            Self.logger.error("SpeziLLMFoundationModels: Generation failed: \(error)")
            await self.finishGenerationWithError(
                LLMFoundationModelsError.generationFailed(underlying: String(describing: error)),
                on: continuationObserver.continuation
            )
        }
#else
        await self.finishGenerationWithError(
            LLMFoundationModelsError.frameworkUnavailable,
            on: continuationObserver.continuation
        )
#endif
    }

    /// Builds the user prompt from the last user message in the context.
    @MainActor
    func buildPrompt() -> String? {
        guard let lastUserMessage = self.context.last(where: { $0.role == .user }) else {
            return nil
        }
        return lastUserMessage.content
    }
}
