//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziLLM


/// Errors that can occur during execution of an ``LLMFoundationModelsSession``.
public enum LLMFoundationModelsError: LLMError {
    /// The Foundation Models framework is not available on the current OS.
    case frameworkUnavailable
    /// The on-device system language model is not available (e.g. Apple Intelligence is disabled or the device is ineligible).
    case modelUnavailable(reason: String)
    /// The session was queried but no user prompt is present in the context.
    case missingPrompt
    /// Generation failed.
    case generationFailed(underlying: String)
    /// Structured output generation failed to decode into the requested type.
    case structuredOutputDecodingFailed(underlying: String)


    public var errorDescription: String? {
        switch self {
        case .frameworkUnavailable:
            "The Foundation Models framework is not available on this OS version."
        case .modelUnavailable(let reason):
            "The on-device language model is not available: \(reason)."
        case .missingPrompt:
            "Cannot generate without a user prompt in the context."
        case .generationFailed(let underlying):
            "Generation failed: \(underlying)."
        case .structuredOutputDecodingFailed(let underlying):
            "Structured output decoding failed: \(underlying)."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .frameworkUnavailable:
            "Run on iOS 26, macOS 26, or visionOS 26 (or newer)."
        case .modelUnavailable:
            "Enable Apple Intelligence in System Settings on a supported device."
        case .missingPrompt:
            "Append a user message to the session context before calling generate()."
        case .generationFailed, .structuredOutputDecodingFailed:
            "Inspect the underlying error and retry with adjusted parameters."
        }
    }

    public var failureReason: String? {
        errorDescription
    }


    public static func == (lhs: LLMFoundationModelsError, rhs: LLMFoundationModelsError) -> Bool {
        switch (lhs, rhs) {
        case (.frameworkUnavailable, .frameworkUnavailable),
             (.missingPrompt, .missingPrompt):
            true
        case let (.modelUnavailable(l), .modelUnavailable(r)):
            l == r
        case let (.generationFailed(l), .generationFailed(r)):
            l == r
        case let (.structuredOutputDecodingFailed(l), .structuredOutputDecodingFailed(r)):
            l == r
        default:
            false
        }
    }
}
