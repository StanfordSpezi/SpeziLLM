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
    /// OpenAI API token is missing.
    case missingAPIToken
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
    /// Invalid function call name
    case invalidFunctionCallName
    /// Invalid function call parameters (mismatch between sent parameters from OpenAI and declared ones within the ``LLMFunction``), including the decoding error
    case invalidFunctionCallArguments(Error)
    /// Exception during function call execution
    case functionCallError(Error)
    
    
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
        case .missingAPIToken:
            String(localized: LocalizedStringResource("LLM_MISSING_TOKEN_ERROR_DESCRIPTION", bundle: .atURL(from: .module)))
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
        case .invalidFunctionCallName:
            String(localized: LocalizedStringResource("LLM_INVALID_FUNCTION_CALL_NAME_ERROR_DESCRIPTION", bundle: .atURL(from: .module)))
        case .invalidFunctionCallArguments:
            String(localized: LocalizedStringResource("LLM_INVALID_FUNCTION_ARGUMENTS_ERROR_DESCRIPTION", bundle: .atURL(from: .module)))
        case .functionCallError:
            String(localized: LocalizedStringResource("LLM_FUNCTION_CALL_ERROR_DESCRIPTION", bundle: .atURL(from: .module)))
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .missingAPIToken:
            String(localized: LocalizedStringResource("LLM_MISSING_TOKEN_RECOVERY_SUGGESTION", bundle: .atURL(from: .module)))
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
        case .invalidFunctionCallName:
            String(localized: LocalizedStringResource("LLM_INVALID_FUNCTION_CALL_NAME_ERROR_RECOVERY_SUGGESTION", bundle: .atURL(from: .module)))
        case .invalidFunctionCallArguments:
            String(localized: LocalizedStringResource("LLM_INVALID_FUNCTION_ARGUMENTS_RECOVERY_SUGGESTION", bundle: .atURL(from: .module)))
        case .functionCallError:
            String(localized: LocalizedStringResource("LLM_FUNCTION_CALL_ERROR_RECOVERY_SUGGESTION", bundle: .atURL(from: .module)))
        }
    }

    public var failureReason: String? {
        switch self {
        case .missingAPIToken:
            String(localized: LocalizedStringResource("LLM_MISSING_TOKEN_FAILURE_REASON", bundle: .atURL(from: .module)))
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
        case .invalidFunctionCallName:
            String(localized: LocalizedStringResource("LLM_INVALID_FUNCTION_CALL_NAME_ERROR_FAILURE_REASON", bundle: .atURL(from: .module)))
        case .invalidFunctionCallArguments:
            String(localized: LocalizedStringResource("LLM_INVALID_FUNCTION_ARGUMENTS_FAILURE_REASON", bundle: .atURL(from: .module)))
        case .functionCallError:
            String(localized: LocalizedStringResource("LLM_FUNCTION_CALL_ERROR_FAILURE_REASON", bundle: .atURL(from: .module)))
        }
    }
    
    
    public static func == (lhs: LLMOpenAIError, rhs: LLMOpenAIError) -> Bool {  // swiftlint:disable:this cyclomatic_complexity
        switch (lhs, rhs) {
        case (.missingAPIToken, .missingAPIToken): true
        case (.invalidAPIToken, .invalidAPIToken): true
        case (.connectivityIssues, .connectivityIssues): true
        case (.storageError, .storageError): true
        case (.insufficientQuota, .insufficientQuota): true
        case (.generationError, .generationError): true
        case (.modelAccessError, .modelAccessError): true
        case (.invalidFunctionCallName, .invalidFunctionCallName): true
        case (.invalidFunctionCallArguments, .invalidFunctionCallArguments): true
        case (.functionCallError, .functionCallError): true
        default: false
        }
    }
}

// Reference: https://platform.openai.com/docs/guides/error-codes/api-errors
extension LLMOpenAISession {
    func handleErrorCode(_ statusCode: Int) -> LLMOpenAIError {
        switch statusCode {
        case 401:
            logger.error("SpeziLLMOpenAI: Invalid OpenAI API token")
            return LLMOpenAIError.invalidAPIToken
        case 403:
            logger.error("SpeziLLMOpenAI: Model access check - Country, region, or territory not supported")
            return LLMOpenAIError.invalidAPIToken
        case 429:
            logger.error("SpeziLLMOpenAI: Rate limit reached for requests")
            return LLMOpenAIError.insufficientQuota
        case 500:
            logger.error("SpeziLLMOpenAI: The server had an error while processing your request")
            return LLMOpenAIError.generationError
        case 503:
            logger.error("SpeziLLMOpenAI: The engine is currently overloaded, please try again later")
            return LLMOpenAIError.generationError
        default:
            logger.error("SpeziLLMOpenAI: Received unknown return code from OpenAI")
            return LLMOpenAIError.generationError
        }
    }
}
