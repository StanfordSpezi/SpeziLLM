//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziLLM


/// Errors that originate from the handling of ``RemoteLLMInferenceAuthToken``.
package enum RemoteLLMInferenceAuthTokenError: LLMError {
    /// The auth method indicated that a token should be in the keychain, however there is none
    case noTokenInKeychain
    /// Couldn't access the keychain
    case keychainAccessError((any Error)? = nil)


    package static func == (lhs: RemoteLLMInferenceAuthTokenError, rhs: RemoteLLMInferenceAuthTokenError) -> Bool {
        switch (lhs, rhs) {
        case (.noTokenInKeychain, .noTokenInKeychain): true
        case (.keychainAccessError, .keychainAccessError): true
        default: false
        }
    }
}
