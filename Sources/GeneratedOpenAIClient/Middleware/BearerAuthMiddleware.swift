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
    private let authToken: @Sendable () async -> String?


    package init(authToken: @Sendable @escaping () async -> String?) {
        self.authToken = authToken
    }


    package func intercept(
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
        return try await next(request, body, baseURL)
    }
}
