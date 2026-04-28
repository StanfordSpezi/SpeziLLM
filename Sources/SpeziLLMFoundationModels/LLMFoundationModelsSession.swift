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
import os
import SpeziChat
import SpeziLLM


/// Represents an executing ``LLMFoundationModelsSchema``.
///
/// The session bridges SpeziLLM's `LLMSession` surface (`generate() -> AsyncThrowingStream<String, ...>`)
/// to Apple's `LanguageModelSession` from the `FoundationModels` framework. A single SpeziLLM session
/// owns a single `LanguageModelSession` and reuses it across calls so that conversational state
/// is preserved on the framework side.
///
/// In addition to the streaming text generation contract, this session exposes a typed
/// ``LLMFoundationModelsSession/generate(generating:)`` overload that streams the partial values of an
/// Apple `@Generable` type — this is the recommended path for structured output on Apple OSes.
///
/// - Warning: ``LLMFoundationModelsSession`` shouldn't be constructed manually. Always go through
/// the SpeziLLM `LLMRunner`.
@Observable
public final class LLMFoundationModelsSession: LLMSession, Sendable {
    static let logger = Logger(subsystem: "edu.stanford.spezi", category: "SpeziLLMFoundationModels")

    let platform: LLMFoundationModelsPlatform
    let schema: LLMFoundationModelsSchema

    /// Holds currently generating continuations so they can be cancelled.
    let continuationHolder = LLMInferenceQueueContinuationHolder()

    @MainActor public var state: LLMState = .uninitialized
    @MainActor public var context: LLMContext = []

#if canImport(FoundationModels)
    /// The underlying framework session, lazily created on first use.
    @MainActor private var languageModelSession: AnyObject?
    /// Number of context entries already sent to the `LanguageModelSession`.
    /// Used to replay only new messages on subsequent `generate()` calls.
    @MainActor var sentContextCount: Int = 0
#endif


    init(_ platform: LLMFoundationModelsPlatform, schema: LLMFoundationModelsSchema) {
        self.platform = platform
        self.schema = schema
    }

    /// Initializes the underlying `LanguageModelSession` ahead of time.
    ///
    /// Calling this before first user interaction reduces latency on the first prompt.
    public func setup() async throws {
        try await ensureSessionReady()
    }

    public func cancel() {
        self.continuationHolder.cancelAll()
    }

    deinit {
        self.cancel()
    }
}


#if canImport(FoundationModels)
@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
extension LLMFoundationModelsSession {
    /// Resolves (and lazily caches) the underlying `LanguageModelSession`.
    @MainActor
    func resolvedLanguageModelSession() throws -> LanguageModelSession {
        if let existing = languageModelSession as? LanguageModelSession {
            return existing
        }

        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            break
        case .unavailable(let reason):
            throw LLMFoundationModelsError.modelUnavailable(reason: String(describing: reason))
        @unknown default:
            throw LLMFoundationModelsError.modelUnavailable(reason: "Unknown availability state.")
        }

        let session: LanguageModelSession
        if let instructions = schema.parameters.instructions {
            session = LanguageModelSession(model: model, instructions: { instructions })
        } else {
            session = LanguageModelSession(model: model)
        }
        languageModelSession = session
        sentContextCount = 0
        return session
    }

    /// Invalidates and recreates the underlying session.
    ///
    /// Called when the SpeziLLM context has been modified in a way that's
    /// incompatible with the `LanguageModelSession`'s internal history
    /// (e.g. messages were removed or edited).
    @MainActor
    func resetLanguageModelSession() throws -> LanguageModelSession {
        languageModelSession = nil
        sentContextCount = 0
        return try resolvedLanguageModelSession()
    }
}
#endif


extension LLMFoundationModelsSession {
    /// Verifies that the framework is available on the current OS and prepares the underlying session.
    func ensureSessionReady() async throws {
#if canImport(FoundationModels)
        guard #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) else {
            throw LLMFoundationModelsError.frameworkUnavailable
        }
        await MainActor.run { self.state = .loading }
        do {
            _ = try await MainActor.run { try self.resolvedLanguageModelSession() }
            await MainActor.run { self.state = .ready }
        } catch {
            await MainActor.run {
                if let llmError = error as? LLMFoundationModelsError {
                    self.state = .error(error: llmError)
                } else {
                    self.state = .error(error: LLMFoundationModelsError.generationFailed(underlying: String(describing: error)))
                }
            }
            throw error
        }
#else
        throw LLMFoundationModelsError.frameworkUnavailable
#endif
    }
}
