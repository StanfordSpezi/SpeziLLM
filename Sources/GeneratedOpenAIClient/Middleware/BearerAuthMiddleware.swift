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
    }

    package enum RemoteLLMInferenceAuthTokenError: Error {
        /// The auth method indicated that a token should be in the keychain, however there is none
        case noTokenInKeychain
    }


    private let authToken: RemoteLLMInferenceAuthTokenInternal


    package init(authToken: RemoteLLMInferenceAuthToken, keychainToken: String?) throws(RemoteLLMInferenceAuthTokenError) {
        if case .keychain = authToken,
           keychainToken == nil {
            throw RemoteLLMInferenceAuthTokenError.noTokenInKeychain
        }

        self.authToken = try .init(from: authToken, keychainToken: keychainToken)
    }


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
