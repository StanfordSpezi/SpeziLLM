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

    // swiftlint:disable:next function_body_length cyclomatic_complexity
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

        do {
            let session = try await MainActor.run { try self.resolvedLanguageModelSession() }

            // Replay any unsent context entries (prior conversation turns) so the
            // LanguageModelSession's internal history stays in sync with our context.
            try await replayUnsentContext(on: session)

            // The last unsent entry must be a user message to generate from.
            let prompt = await MainActor.run { self.lastUnsentUserPrompt() }
            guard let prompt else {
                await self.finishGenerationWithError(
                    LLMFoundationModelsError.missingPrompt,
                    on: continuationObserver.continuation
                )
                return
            }

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

            // Mark everything (including the assistant reply we just injected) as sent.
            await MainActor.run {
                self.sentContextCount = self.context.count
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
}


#if canImport(FoundationModels)
@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
extension LLMFoundationModelsSession {
    /// Returns the last user message in the context that hasn't been sent yet, if any.
    @MainActor
    func lastUnsentUserPrompt() -> String? {
        let unsent = Array(context[sentContextCount...])
        guard let lastUser = unsent.last(where: { $0.role == .user }) else {
            return nil
        }
        return lastUser.content
    }

    /// Replays unsent context entries to the `LanguageModelSession` so its internal
    /// history matches ours.
    ///
    /// For each prior user message that we haven't sent yet (excluding the very last one
    /// which will be streamed), we call `respond(to:)` and discard the response — the
    /// session records the turn internally. System messages are skipped since they were
    /// already provided as instructions at session creation. Assistant messages are also
    /// skipped since they represent prior model responses already tracked by the session.
    ///
    /// If the context was modified (e.g. entries before the sent watermark were removed),
    /// we reset the session and replay from the start.
    func replayUnsentContext(on session: LanguageModelSession) async throws {
        let (contextSnapshot, sent) = await MainActor.run {
            (Array(self.context), self.sentContextCount)
        }

        // Detect context modification: if the context shrank below our watermark,
        // the user removed messages — we must start over.
        if contextSnapshot.count < sent {
            _ = try await MainActor.run { try self.resetLanguageModelSession() }
            try await replayUnsentContext(on: await MainActor.run { try self.resolvedLanguageModelSession() })
            return
        }

        let unsent = Array(contextSnapshot[sent...])

        // Find the last user message index among the unsent entries — that one
        // will be streamed, so we only replay everything before it.
        guard let lastUserIndex = unsent.lastIndex(where: { $0.role == .user }) else {
            return
        }
        let toReplay = unsent[unsent.startIndex..<lastUserIndex]

        for entry in toReplay {
            switch entry.role {
            case .user:
                // Replay this prior user turn. The session records the exchange.
                _ = try await session.respond(to: entry.content, options: self.schema.parameters.generationOptions)
            case .system, .assistant, .tool:
                // System instructions are set at session creation.
                // Assistant and tool messages are the session's own output.
                continue
            }
        }

        // Update the watermark to cover everything up to (but not including) the last user message.
        await MainActor.run {
            self.sentContextCount = sent + (lastUserIndex - unsent.startIndex)
        }
    }
}
#endif
