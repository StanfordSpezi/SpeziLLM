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
import SpeziLLM


#if canImport(FoundationModels)
/// Structured output generation using Apple's `@Generable` types.
///
/// ### Usage
///
/// ```swift
/// @Generable
/// struct MedicalSummary {
///     var diagnosis: String
///     var confidence: Double
/// }
///
/// let session: LLMFoundationModelsSession = runner(
///     with: LLMFoundationModelsSchema()
/// )
///
/// // Append user message, then generate a complete value:
/// await MainActor.run { session.context.append(userInput: "Summarize the diagnosis.") }
/// let summary = try await session.generate(generating: MedicalSummary.self)
/// ```
@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
extension LLMFoundationModelsSession {
    /// Streams partial values of a `@Generable` type during generation.
    ///
    /// Each yielded value is a `T.PartiallyGenerated` snapshot — the partially populated
    /// representation of the final `T`. Use `generateComplete(generating:)` if you only
    /// need the final result.
    ///
    /// - Parameter type: The `@Generable` type to generate.
    /// - Returns: An `AsyncThrowingStream` of progressively more complete partial values.
    public func streamStructured<T: Generable>(
        generating type: T.Type
    ) async throws -> AsyncThrowingStream<T.PartiallyGenerated, any Error> where T.PartiallyGenerated: Sendable {
        let prompt = await MainActor.run { self.lastUnsentUserPrompt() }
        guard let prompt else {
            throw LLMFoundationModelsError.missingPrompt
        }

        try await ensureSessionReady()

        await MainActor.run {
            self.state = .generating
        }

        let session = try await MainActor.run { try self.resolvedLanguageModelSession() }
        try await replayUnsentContext(on: session)

        let (outputStream, outputContinuation) = AsyncThrowingStream<T.PartiallyGenerated, any Error>.makeStream()

        let sendablePrompt = prompt
        let sendableOptions = self.schema.parameters.generationOptions

        Task {
            do {
                let stream = session.streamResponse(
                    to: sendablePrompt,
                    generating: type,
                    options: sendableOptions
                )

                for try await snapshot in stream {
                    outputContinuation.yield(snapshot.content)
                }
                outputContinuation.finish()

                await MainActor.run {
                    self.sentContextCount = self.context.count
                    self.state = .ready
                }
            } catch {
                Self.logger.error("SpeziLLMFoundationModels: Structured output streaming failed: \(error)")
                outputContinuation.finish(throwing: LLMFoundationModelsError.structuredOutputDecodingFailed(
                    underlying: String(describing: error)
                ))
                await MainActor.run {
                    self.state = .error(error: LLMFoundationModelsError.structuredOutputDecodingFailed(
                        underlying: String(describing: error)
                    ))
                }
            }
        }

        return outputStream
    }

    /// Generates structured output and returns the final complete value.
    ///
    /// - Parameter type: The `@Generable` type to generate.
    /// - Returns: The fully-generated value of type `T`.
    public func generate<T: Generable>(
        generating type: T.Type
    ) async throws -> T {
        let prompt = await MainActor.run { self.lastUnsentUserPrompt() }
        guard let prompt else {
            throw LLMFoundationModelsError.missingPrompt
        }

        try await ensureSessionReady()

        await MainActor.run {
            self.state = .generating
        }

        do {
            let session = try await MainActor.run { try self.resolvedLanguageModelSession() }
            try await replayUnsentContext(on: session)
            let response = try await session.respond(
                to: prompt,
                generating: type,
                options: self.schema.parameters.generationOptions
            )

            await MainActor.run {
                self.sentContextCount = self.context.count
                self.state = .ready
            }

            return response.content
        } catch {
            Self.logger.error("SpeziLLMFoundationModels: Structured output generation failed: \(error)")
            let wrappedError = LLMFoundationModelsError.structuredOutputDecodingFailed(
                underlying: String(describing: error)
            )
            await MainActor.run {
                self.state = .error(error: wrappedError)
            }
            throw wrappedError
        }
    }
}
#endif
