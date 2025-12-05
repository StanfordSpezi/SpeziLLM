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


    /// Build the middleware from a ``RemoteLLMInferenceAuthToken``.
    ///
    /// - Parameters:
    ///   - authToken: The auth token and its type.
    ///   - keychainStorage: The key chain storage layer.
    package init(
        authToken: RemoteLLMInferenceAuthToken,
        keychainStorage: KeychainStorage?
    ) {
        self.authToken = authToken
        self.keychainStorage = keychainStorage

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
        let authToken = try await self.authToken.getToken(keychainStorage: keychainStorage)

        var request = request
        if let authToken {
            request.headerFields[.authorization] = "Bearer \(authToken)"
        }
        return try await next(request, body, baseURL)
    }
}
