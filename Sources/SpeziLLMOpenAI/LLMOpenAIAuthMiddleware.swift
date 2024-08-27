// Based on: https://github.com/apple/swift-openapi-generator/blob/main/Examples/auth-client-middleware-example/Sources/AuthenticationClientMiddleware/AuthenticationClientMiddleware.swift

import Foundation
import HTTPTypes
import OpenAPIRuntime

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
