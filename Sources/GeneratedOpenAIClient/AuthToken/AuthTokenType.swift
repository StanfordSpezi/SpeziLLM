//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziKeychainStorage


/// The type of auth token for remote LLM services, such as the OpenAI or Fog layer.
public enum RemoteLLMInferenceAuthToken: Sendable {
    /// No auth token.
    case none
    /// Constant auth token that is static during the lifetime of the ``RemoteLLMInferenceAuthToken``.
    case constant(String)
    /// Auth token persisted in the keychain tagged with the `CredentialsTag` and username, dynamically read from the keychain upon every request.
    case keychain(tag: CredentialsTag, username: String)
    /// Auth token dynamically produced by a closure, reevaluated upon every request.
    case closure(@Sendable () async -> String?)
}


extension RemoteLLMInferenceAuthToken {
    package func getToken(keychainStorage: KeychainStorage?) async throws -> String? {
        switch self {
        case .none:
            return nil

        case .constant(let string):
            return string

        case let .keychain(credentialsTag, username):  // extract the keychain token on every request
            let credential: Credentials?

            do {
                credential = try keychainStorage?.retrieveCredentials(
                    withUsername: username,
                    for: credentialsTag
                )
            } catch {
                throw RemoteLLMInferenceAuthTokenError.keychainAccessError(error)
            }

            guard let credentialToken = credential?.password else {
                throw RemoteLLMInferenceAuthTokenError.noTokenInKeychain
            }

            return credentialToken

        case .closure(let tokenClosure):
            return await tokenClosure()
        }
    }
}
