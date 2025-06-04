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


/// Middleware for injecting an Bearer API token into outgoing requests based on the ``RemoteLLMInferenceAuthToken``.
package struct BearerAuthMiddleware: ClientMiddleware {
    private let authToken: RemoteLLMInferenceAuthToken
    private let keychainStorage: KeychainStorage?
    private let keychainUsername: String?


    /// Build the middleware from a ``RemoteLLMInferenceAuthToken``.
    ///
    /// - Parameters:
    ///   - authToken: The auth token and its type.
    ///   - keychainStorage: The key chain storage layer.
    ///   - keychainUsername: The key chain user name.
    package init(
        authToken: RemoteLLMInferenceAuthToken,
        keychainStorage: KeychainStorage?,
        keychainUsername: String?
    ) {
        self.authToken = authToken
        self.keychainStorage = keychainStorage
        self.keychainUsername = keychainUsername

        // Check if keychain storage is specified
        if case .keychain = authToken {
            guard self.keychainStorage != nil else {
                fatalError("Internal consistency error: Keychain storage could no be accessed, even though it was specified")
            }
        }
    }

    
    /// Intercepting outgoing requests by injecting a Bearer auth token into the header.
    ///
    /// On every request, it fetches the keychain token or reevaluates the auth token closure, depending on the ``RemoteLLMInferenceAuthToken``
    package func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID _: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        let authToken: String?

        switch self.authToken {
        case .none:
            authToken = nil

        case .constant(let string):
            authToken = string

        case .keychain(let credentialsTag):  // extract the keychain token on every request
            let credential: Credentials?

            do {
                credential = try keychainStorage?.retrieveCredentials(
                    withUsername: keychainUsername,
                    for: credentialsTag
                )
            } catch {
                throw RemoteLLMInferenceAuthTokenError.keychainAccessError(error)
            }

            guard let credentialToken = credential?.password else {
                throw RemoteLLMInferenceAuthTokenError.noTokenInKeychain
            }

            authToken = credentialToken

        case .closure(let tokenClosure):    // reevaluate the auth token closure on every request
            authToken = await tokenClosure()
        }

        var request = request
        if let authToken {
            request.headerFields[.authorization] = "Bearer \(authToken)"
        }
        return try await next(request, body, baseURL)
    }
}
