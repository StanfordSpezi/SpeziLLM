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


/// A `ClientMiddleware` for injecting the Firebase Auth token into outgoing requests so that the Fog Node can verify the authenticity of requests.
/// Also sets the expected hostname of the request, required for proper custom TLS verification.
struct AuthMiddleware: ClientMiddleware {
    private let hostHeaderKey: HTTPField.Name = {
        guard let hostHeader = HTTPField.Name("Host") else {
            preconditionFailure("SpeziLLMFog: Failed to create HTTPField.Name for `Host`.")
        }

        return hostHeader
    }()

    private let authToken: @Sendable () async -> String?
    private let expectedHost: String?


    init(authToken: @Sendable @escaping () async -> String?, expectedHost: String?) {
        self.authToken = authToken
        self.expectedHost = expectedHost
    }


    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID _: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var request = request
        if let authToken = await self.authToken() {
            request.headerFields[.authorization] = "Bearer \(authToken)"
        }
        if let expectedHost = expectedHost {
            request.headerFields[hostHeaderKey] = expectedHost
        }
        return try await next(request, body, baseURL)
    }
}
