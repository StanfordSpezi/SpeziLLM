//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import HTTPTypes
import OpenAPIRuntime
import SpeziKeychainStorage
import SpeziLLM


/// Middleware for injecting an API token into outgoing requests.
package struct BearerAuthMiddleware: ClientMiddleware {
    /// The type of auth token, either a constant one or a dynamically generated one via a closure.
    enum RemoteLLMInferenceAuthTokenInternal: Sendable {
        /// No auth token
        case none
        /// Content auth token that is hardcoded
        case constant(String)
        /// Auth token is derived from user input and stored in keychain
        case keychain(String)
        /// Dynamic auth token produced by closure.
        case closure(@Sendable () async -> String?)


        var token: String? {
            get async {
                switch self {
                case .none:
                    return nil
                case .constant(let token):
                    return token
                case .keychain(let token):
                    return token
                case .closure(let tokenClosure):
                    return await tokenClosure()
                }
            }
        }


        init(from authToken: RemoteLLMInferenceAuthToken, keychainToken: String?) throws(RemoteLLMInferenceAuthTokenError) {
            switch authToken {
            case .none:
                self = .none
            case .constant(let token):
                self = .constant(token)
            case .keychain:
                guard let keychainToken else {
                    throw RemoteLLMInferenceAuthTokenError.noTokenInKeychain
                }

                self = .keychain(keychainToken)
            case .closure(let tokenClosure):
                self = .closure(tokenClosure)
            }
        }
    }


    private let authToken: RemoteLLMInferenceAuthTokenInternal


    package init(authToken: RemoteLLMInferenceAuthToken, keychainToken: String?) throws(RemoteLLMInferenceAuthTokenError) {
        if case .keychain = authToken,
           keychainToken == nil {
            throw RemoteLLMInferenceAuthTokenError.noTokenInKeychain
        }

        self.authToken = try .init(from: authToken, keychainToken: keychainToken)
    }


    /// Build the middleware from the ``RemoteLLMInferenceAuthToken``.
    ///
    /// - Parameters:
    ///   - authToken: The auth token and its type.
    ///   - keychainStorage: The key chain storage layer.
    ///   - keychainUsername: The key chain user name.
    package static func build(
        authToken: RemoteLLMInferenceAuthToken,
        keychainStorage: KeychainStorage?,
        keychainUsername: String?
    ) throws(RemoteLLMInferenceAuthTokenError) -> Self {
        // Extract token from keychain if specified
        if case .keychain(let credentialTag) = authToken {
            let credential: Credentials?

            guard let keychainStorage else {
                throw RemoteLLMInferenceAuthTokenError.keychainAccessError()
            }

            do {
                credential = try keychainStorage.retrieveCredentials(
                    withUsername: keychainUsername,
                    for: credentialTag
                )
            } catch {
                throw RemoteLLMInferenceAuthTokenError.keychainAccessError(error)
            }

            guard let credentialToken = credential?.password else {
                throw RemoteLLMInferenceAuthTokenError.noTokenInKeychain
            }

            return try .init(authToken: authToken, keychainToken: credentialToken)
        } else {
            return try .init(authToken: authToken, keychainToken: nil)
        }
    }


    /// Intercepting outgoing requests by injecting a Bearer auth token into the header.
    package func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID _: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var request = request
        if let authToken = await self.authToken.token {
            request.headerFields[.authorization] = "Bearer \(authToken)"
        }
        return try await next(request, body, baseURL)
    }
}
