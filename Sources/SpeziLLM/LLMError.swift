//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// The ``LLMError`` describes possible errors that occur during the execution of the ``LLM`` via the ``LLMRunner``.
public enum LLMError: LocalizedError {
    /// Indicates that the local model file is not found.
    case modelNotFound
    /// Indicates that the ``LLM`` is not yet ready, e.g., not initialized.
    case modelNotReadyYet
    /// Indicates that during generation an error occurred.
    case generationError
    
    
    public var errorDescription: String? {
        switch self {
        case .modelNotFound:
            String(localized: LocalizedStringResource("LLM_MODEL_NOT_FOUND_ERROR_DESCRIPTION", bundle: .atURL(from: .module)))
        case .modelNotReadyYet:
            String(localized: LocalizedStringResource("LLM_MODEL_NOT_READY_ERROR_DESCRIPTION", bundle: .atURL(from: .module)))
        case .generationError:
            String(localized: LocalizedStringResource("LLM_GENERATION_ERROR_DESCRIPTION", bundle: .atURL(from: .module)))
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
        }
    }
}
