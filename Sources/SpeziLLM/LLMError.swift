//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// Defines errors that may occur during setting up the runner environment for ``LLM`` generation jobs.
public enum LLMRunnerError: LLMError {
    /// Indicates an error occurred during setup of the LLM generation.
    case setupError
    
    
    public var errorDescription: String? {
        switch self {
        case .setupError:
            String(localized: LocalizedStringResource("LLM_SETUP_ERROR_DESCRIPTION", bundle: .atURL(from: .module)))
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .setupError:
            String(localized: LocalizedStringResource("LLM_SETUP_ERROR_RECOVERY_SUGGESTION", bundle: .atURL(from: .module)))
        }
    }

    public var failureReason: String? {
        switch self {
        case .setupError:
            String(localized: LocalizedStringResource("LLM_SETUP_ERROR_FAILURE_REASON", bundle: .atURL(from: .module)))
        }
    }
}


/// The ``LLMError`` defines a common error protocol which should be used for defining errors within the SpeziLLM ecosystem.
public protocol LLMError: LocalizedError, Equatable {}


extension CancellationError: LLMError {
    public static func == (lhs: CancellationError, rhs: CancellationError) -> Bool {
        true
    }
}
