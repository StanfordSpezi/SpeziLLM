import Foundation

/// Error that occur during requesting access to the local network for discovering fog nodes.
public enum LLMFogOnboardingDiscoveryError: LocalizedError {
    /// Indicates that the user denied the authorization to access the local network
    case authorizationDenied
    /// Indicates that the authorization to access the local network could not be completed
    case authorizationFailed


    public var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            String(localized: LocalizedStringResource("FOG_DISCOVERY_AUTHORIZATION_DENIED_ERROR_DESCRIPTION", bundle: .atURL(from: .module)))
        case .authorizationFailed:
            String(localized: LocalizedStringResource("FOG_DISCOVERY_AUTHORIZATION_FAILED_ERROR_DESCRIPTION", bundle: .atURL(from: .module)))
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .authorizationDenied:
            String(localized: LocalizedStringResource("FOG_DISCOVERY_AUTHORIZATION_DENIED_RECOVERY_SUGGESTION", bundle: .atURL(from: .module)))
        case .authorizationFailed:
            String(localized: LocalizedStringResource("FOG_DISCOVERY_AUTHORIZATION_FAILED_RECOVERY_SUGGESTION", bundle: .atURL(from: .module)))
        }
    }

    public var failureReason: String? {
        switch self {
        case .authorizationDenied:
            String(localized: LocalizedStringResource("FOG_DISCOVERY_AUTHORIZATION_DENIED_FAILURE_REASON", bundle: .atURL(from: .module)))
        case .authorizationFailed:
            String(localized: LocalizedStringResource("FOG_DISCOVERY_AUTHORIZATION_FAILED_FAILURE_REASON", bundle: .atURL(from: .module)))
        }
    }
}
