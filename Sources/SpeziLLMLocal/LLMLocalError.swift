//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziLLM


/// The ``LLMLocalError`` describes possible errors that occur during the execution of ``LLMLocal`` via the SpeziLLM `LLMRunner`.
public enum LLMLocalError: LLMError {
    /// Indicates that the local model file is not found.
    case modelNotFound
    /// Indicates that the ``LLMLocal`` is not yet ready, e.g., not initialized.
    case modelNotReadyYet
    /// Indicates that during generation an error occurred.
    case generationError
    /// Indicates error occurring during tokenizing the user input
    case illegalContext
    /// Indicates a mismatch between training context tokens and configured tokens
    case contextSizeMismatch
    
    
    public var errorDescription: String? {
        switch self {
        case .modelNotFound:
            String(localized: LocalizedStringResource("LLM_MODEL_NOT_FOUND_ERROR_DESCRIPTION", bundle: .atURL(from: .module)))
        case .modelNotReadyYet:
            String(localized: LocalizedStringResource("LLM_MODEL_NOT_READY_ERROR_DESCRIPTION", bundle: .atURL(from: .module)))
        case .generationError:
            String(localized: LocalizedStringResource("LLM_GENERATION_ERROR_DESCRIPTION", bundle: .atURL(from: .module)))
        case .illegalContext:
            String(localized: LocalizedStringResource("LLM_ILLEGAL_CONTEXT_ERROR_DESCRIPTION", bundle: .atURL(from: .module)))
        case .contextSizeMismatch:
            String(localized: LocalizedStringResource("LLM_CONTEXT_SIZE_MISMATCH_ERROR_DESCRIPTION", bundle: .atURL(from: .module)))
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .modelNotFound:
            String(localized: LocalizedStringResource("LLM_MODEL_NOT_FOUND_RECOVERY_SUGGESTION", bundle: .atURL(from: .module)))
        case .modelNotReadyYet:
            String(localized: LocalizedStringResource("LLM_MODEL_NOT_READY_RECOVERY_SUGGESTION", bundle: .atURL(from: .module)))
        case .generationError:
            String(localized: LocalizedStringResource("LLM_GENERATION_ERROR_RECOVERY_SUGGESTION", bundle: .atURL(from: .module)))
        case .illegalContext:
            String(localized: LocalizedStringResource("LLM_ILLEGAL_CONTEXT_ERROR_RECOVERY_SUGGESTION", bundle: .atURL(from: .module)))
        case .contextSizeMismatch:
            String(localized: LocalizedStringResource("LLM_CONTEXT_SIZE_MISMATCH_ERROR_RECOVERY_SUGGESTION", bundle: .atURL(from: .module)))
        }
    }

    public var failureReason: String? {
        switch self {
        case .modelNotFound:
            String(localized: LocalizedStringResource("LLM_MODEL_NOT_FOUND_FAILURE_REASON", bundle: .atURL(from: .module)))
        case .modelNotReadyYet:
            String(localized: LocalizedStringResource("LLM_MODEL_NOT_READY_FAILURE_REASON", bundle: .atURL(from: .module)))
        case .generationError:
            String(localized: LocalizedStringResource("LLM_GENERATION_ERROR_FAILURE_REASON", bundle: .atURL(from: .module)))
        case .illegalContext:
            String(localized: LocalizedStringResource("LLM_ILLEGAL_CONTEXT_ERROR_FAILURE_REASON", bundle: .atURL(from: .module)))
        case .contextSizeMismatch:
            String(localized: LocalizedStringResource("LLM_CONTEXT_SIZE_MISMATCH_ERROR_FAILURE_REASON", bundle: .atURL(from: .module)))
        }
    }
}
