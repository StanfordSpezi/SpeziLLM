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


/// Middleware to set the expected host name of the request, required for proper custom TLS verification.
struct ExpectedHostMiddleware: ClientMiddleware {
    private let hostHeaderKey: HTTPField.Name = {
        guard let hostHeader = HTTPField.Name("Host") else {
            fatalError("SpeziLLMFog: Failed to create HTTPField.Name for `Host`.")
        }

        return hostHeader
    }()

    private let expectedHost: String?


    init(expectedHost: String?) {
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
        if let expectedHost = expectedHost {
            request.headerFields[hostHeaderKey] = expectedHost
        }
        return try await next(request, body, baseURL)
    }
}
