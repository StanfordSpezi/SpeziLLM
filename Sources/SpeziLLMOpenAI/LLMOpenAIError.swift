//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziLLM


/// Errors that can occur by interacting with the OpenAI API.
public enum LLMOpenAIError: LLMError {
    /// OpenAI API token is invalid.
    case invalidAPIToken
    /// Connectivity error
    case connectivityIssues(URLError)
    /// Couldn't store the OpenAI token to a secure storage location
    case storageError
    /// Quota limit reached
    case insufficientQuota
    /// Error during generation
    case generationError
    /// Error during accessing the OpenAI Model
    case modelAccessError(Error)
    /// Unknown error
    case unknownError(Error)
    
    
    /// Maps the enum cases to error message from the OpenAI API
    var openAIErrorMessage: String? {
        switch self {
        case .invalidAPIToken: "invalid_api_key"
        case .insufficientQuota: "insufficient_quota"
        default: nil
        }
    }
    
    public var errorDescription: String? {
        switch self {
        case .invalidAPIToken:
            String(localized: LocalizedStringResource("LLM_INVALID_TOKEN_ERROR_DESCRIPTION", bundle: .atURL(from: .module)))
        case .connectivityIssues:
            String(localized: LocalizedStringResource("LLM_CONNECTIVITY_ERROR_DESCRIPTION", bundle: .atURL(from: .module)))
        case .storageError:
            String(localized: LocalizedStringResource("LLM_STORAGE_ERROR_DESCRIPTION", bundle: .atURL(from: .module)))
        case .insufficientQuota:
            String(localized: LocalizedStringResource("LLM_INSUFFICIENT_QUOTA_ERROR_DESCRIPTION", bundle: .atURL(from: .module)))
        case .generationError:
            String(localized: LocalizedStringResource("LLM_GENERATION_ERROR_DESCRIPTION", bundle: .atURL(from: .module)))
        case .modelAccessError:
            String(localized: LocalizedStringResource("LLM_MODEL_ACCESS_ERROR_DESCRIPTION", bundle: .atURL(from: .module)))
        case .unknownError:
            String(localized: LocalizedStringResource("LLM_UNKNOWN_ERROR_DESCRIPTION", bundle: .atURL(from: .module)))
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .invalidAPIToken:
            String(localized: LocalizedStringResource("LLM_INVALID_TOKEN_RECOVERY_SUGGESTION", bundle: .atURL(from: .module)))
        case .connectivityIssues:
            String(localized: LocalizedStringResource("LLM_CONNECTIVITY_ERROR_RECOVERY_SUGGESTION", bundle: .atURL(from: .module)))
        case .storageError:
            String(localized: LocalizedStringResource("LLM_STORAGE_ERROR_RECOVERY_SUGGESTION", bundle: .atURL(from: .module)))
        case .insufficientQuota:
            String(localized: LocalizedStringResource("LLM_INSUFFICIENT_QUOTA_RECOVERY_SUGGESTION", bundle: .atURL(from: .module)))
        case .generationError:
            String(localized: LocalizedStringResource("LLM_GENERATION_ERROR_RECOVERY_SUGGESTION", bundle: .atURL(from: .module)))
        case .modelAccessError:
            String(localized: LocalizedStringResource("LLM_MODEL_ACCESS_ERROR_RECOVERY_SUGGESTION", bundle: .atURL(from: .module)))
        case .unknownError:
            String(localized: LocalizedStringResource("LLM_UNKNOWN_ERROR_RECOVERY_SUGGESTION", bundle: .atURL(from: .module)))
        }
    }

    public var failureReason: String? {
        switch self {
        case .invalidAPIToken:
            String(localized: LocalizedStringResource("LLM_INVALID_TOKEN_FAILURE_REASON", bundle: .atURL(from: .module)))
        case .connectivityIssues:
            String(localized: LocalizedStringResource("LLM_CONNECTIVITY_ERROR_FAILURE_REASON", bundle: .atURL(from: .module)))
        case .storageError:
            String(localized: LocalizedStringResource("LLM_STORAGE_ERROR_FAILURE_REASON", bundle: .atURL(from: .module)))
        case .insufficientQuota:
            String(localized: LocalizedStringResource("LLM_INSUFFICIENT_QUOTA_FAILURE_REASON", bundle: .atURL(from: .module)))
        case .generationError:
            String(localized: LocalizedStringResource("LLM_GENERATION_ERROR_FAILURE_REASON", bundle: .atURL(from: .module)))
        case .modelAccessError:
            String(localized: LocalizedStringResource("LLM_MODEL_ACCESS_ERROR_FAILURE_REASON", bundle: .atURL(from: .module)))
        case .unknownError:
            String(localized: LocalizedStringResource("LLM_UNKNOWN_ERROR_FAILURE_REASON", bundle: .atURL(from: .module)))
        }
    }
    
    
    public static func == (lhs: LLMOpenAIError, rhs: LLMOpenAIError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidAPIToken, .invalidAPIToken): true
        case (.connectivityIssues, .connectivityIssues): true
        case (.insufficientQuota, .insufficientQuota): true
        case (.generationError, .generationError): true
        case (.unknownError, .unknownError): true
        default: false
        }
    }
}
