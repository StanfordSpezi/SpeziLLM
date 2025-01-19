//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

// Reference: https://github.com/apple/swift-openapi-generator/blob/main/Examples/auth-client-middleware-example/Sources/AuthenticationClientMiddleware/AuthenticationClientMiddleware.swift

import Foundation
import HTTPTypes
import OpenAPIRuntime

/// A `ClientMiddleware` for injecting the OpenAI API key into outgoing requests.
struct AuthMiddleware: ClientMiddleware {
    private let APIKey: String

    init(APIKey: String) { self.APIKey = APIKey }

    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID _: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var request = request
        request.headerFields[.authorization] = "Bearer \(APIKey)"
        return try await next(request, body, baseURL)
    }
}
