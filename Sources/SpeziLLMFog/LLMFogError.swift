//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Network
import SpeziLLM


/// Errors that can occur by interacting with Fog LLMs.
public enum LLMFogError: LLMError {
    /// Fog LLM user token is invalid.
    case invalidAPIToken
    /// Connectivity error
    case connectivityIssues(any Error)
    /// Error during generation
    case generationError
    /// Error during accessing the Fog LLM Model
    case modelAccessError(String)
    /// Fog CA certificate is missing / not readable.
    case missingCaCertificate
    /// No mDNS services were found
    case mDnsServicesNotFound
    /// Network error during mDNS service discovery.
    case mDnsServiceDiscoveryNetworkError
    /// Unknown error
    case unknownError(String)

    
    public var errorDescription: String? {
        switch self {
        case .invalidAPIToken:
            String(localized: LocalizedStringResource("LLM_INVALID_TOKEN_ERROR_DESCRIPTION", bundle: .atURL(from: .module)))
        case .connectivityIssues:
            String(localized: LocalizedStringResource("LLM_CONNECTIVITY_ERROR_DESCRIPTION", bundle: .atURL(from: .module)))
        case .generationError:
            String(localized: LocalizedStringResource("LLM_GENERATION_ERROR_DESCRIPTION", bundle: .atURL(from: .module)))
        case .modelAccessError:
            String(localized: LocalizedStringResource("LLM_MODEL_ACCESS_ERROR_DESCRIPTION", bundle: .atURL(from: .module)))
        case .missingCaCertificate:
            String(localized: LocalizedStringResource("LLM_MISSING_CA_CERT_ERROR_DESCRIPTION", bundle: .atURL(from: .module)))
        case .mDnsServicesNotFound:
            String(localized: LocalizedStringResource("LLM_NO_MDNS_SERVICE_FOUND_ERROR_DESCRIPTION", bundle: .atURL(from: .module)))
        case .mDnsServiceDiscoveryNetworkError:
            String(localized: LocalizedStringResource("LLM_SERIVE_DISCOVERY_ERROR_DESCRIPTION", bundle: .atURL(from: .module)))
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
        case .generationError:
            String(localized: LocalizedStringResource("LLM_GENERATION_ERROR_RECOVERY_SUGGESTION", bundle: .atURL(from: .module)))
        case .modelAccessError:
            String(localized: LocalizedStringResource("LLM_MODEL_ACCESS_ERROR_RECOVERY_SUGGESTION", bundle: .atURL(from: .module)))
        case .missingCaCertificate:
            String(localized: LocalizedStringResource("LLM_MISSING_CA_CERT_ERROR_RECOVERY_SUGGESTION", bundle: .atURL(from: .module)))
        case .mDnsServicesNotFound:
            String(localized: LocalizedStringResource("LLM_NO_MDNS_SERVICE_FOUND_ERROR_RECOVERY_SUGGESTION", bundle: .atURL(from: .module)))
        case .mDnsServiceDiscoveryNetworkError:
            String(localized: LocalizedStringResource("LLM_SERIVE_DISCOVERY_ERROR_RECOVERY_SUGGESTION", bundle: .atURL(from: .module)))
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
        case .generationError:
            String(localized: LocalizedStringResource("LLM_GENERATION_ERROR_FAILURE_REASON", bundle: .atURL(from: .module)))
        case .modelAccessError:
            String(localized: LocalizedStringResource("LLM_MODEL_ACCESS_ERROR_FAILURE_REASON", bundle: .atURL(from: .module)))
        case .missingCaCertificate:
            String(localized: LocalizedStringResource("LLM_MISSING_CA_CERT_ERROR_FAILURE_REASON", bundle: .atURL(from: .module)))
        case .mDnsServicesNotFound:
            String(localized: LocalizedStringResource("LLM_NO_MDNS_SERVICE_FOUND_ERROR_FAILURE_REASON", bundle: .atURL(from: .module)))
        case .mDnsServiceDiscoveryNetworkError:
            String(localized: LocalizedStringResource("LLM_SERIVE_DISCOVERY_ERROR_FAILURE_REASON", bundle: .atURL(from: .module)))
        case .unknownError:
            String(localized: LocalizedStringResource("LLM_UNKNOWN_ERROR_FAILURE_REASON", bundle: .atURL(from: .module)))
        }
    }
    
    
    public static func == (lhs: LLMFogError, rhs: LLMFogError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidAPIToken, .invalidAPIToken): true
        case (.connectivityIssues, .connectivityIssues): true
        case (.generationError, .generationError): true
        case (.modelAccessError, .modelAccessError): true
        case (.missingCaCertificate, .missingCaCertificate): true
        case (.mDnsServicesNotFound, .mDnsServicesNotFound): true
        case (.mDnsServiceDiscoveryNetworkError, .mDnsServiceDiscoveryNetworkError): true
        case (.unknownError, .unknownError): true
        default: false
        }
    }
}


extension LLMFogSession {
    private static let modelNotFoundRegex = "model '([\\w:]+)' not found, try pulling it first"


    func handleErrorCode(statusCode: Int, message: String?) -> LLMFogError {
        switch statusCode {
        case 401, 403:
            Self.logger.error("SpeziLLMFog: LLM model could not be accessed as the passed authentication token is invalid.")
            return .invalidAPIToken
        case 404:
            if let message,
               message.range(of: Self.modelNotFoundRegex, options: .regularExpression) != nil {
                LLMFogSession.logger.error("SpeziLLMFog: Model could not be accessed, ensure to pull it first on the Ollama fog node: \(message)")
                return .modelAccessError(message)
            }
            fallthrough
        default:
            LLMFogSession.logger.error("SpeziLLMFog: Unknown error occurred: \(statusCode) \(message ?? "")")
            return .unknownError("\(statusCode) \(message ?? "")")
        }
    }
}
