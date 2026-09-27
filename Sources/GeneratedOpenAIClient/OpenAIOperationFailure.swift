//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import OpenAPIRuntime


/// A response other than the documented success, reduced to the status code the API answered with.
///
/// The OpenAI document describes rate limiting and unavailability as responses of their own, so the generated
/// outputs carry them as typed cases next to `undocumented`. Callers that map status codes to errors treat them
/// all the same way through this type.
package struct OpenAIOperationFailure: Sendable {
    /// The HTTP status code the API answered with.
    package let statusCode: Int
    /// The message the API attached to the failure, where the document describes the body.
    package let message: String?
    /// The raw body of a response the document does not describe.
    package let undocumentedBody: HTTPBody?


    fileprivate init(statusCode: Int, message: String? = nil, undocumentedBody: HTTPBody? = nil) {
        self.statusCode = statusCode
        self.message = message
        self.undocumentedBody = undocumentedBody
    }
}


extension Operations.createChatCompletion.Output {
    /// The failure this response reports, or `nil` for the documented success.
    package var failure: OpenAIOperationFailure? {
        switch self {
        case .ok:
            nil
        case .tooManyRequests(let response):
            .init(statusCode: 429, message: (try? response.body.json)?.error.message)
        case .serviceUnavailable(let response):
            .init(statusCode: 503, message: (try? response.body.json)?.error.message)
        case let .undocumented(statusCode, payload):
            .init(statusCode: statusCode, undocumentedBody: payload.body)
        }
    }
}


extension Operations.createResponse.Output {
    /// The failure this response reports, or `nil` for the documented success.
    package var failure: OpenAIOperationFailure? {
        switch self {
        case .ok:
            nil
        case .tooManyRequests(let response):
            .init(statusCode: 429, message: (try? response.body.json)?.error.message)
        case .serviceUnavailable(let response):
            .init(statusCode: 503, message: (try? response.body.json)?.error.message)
        case let .undocumented(statusCode, payload):
            .init(statusCode: statusCode, undocumentedBody: payload.body)
        }
    }
}


extension Operations.retrieveModel.Output {
    /// The failure this response reports, or `nil` for the documented success.
    package var failure: OpenAIOperationFailure? {
        switch self {
        case .ok:
            nil
        case let .undocumented(statusCode, payload):
            .init(statusCode: statusCode, undocumentedBody: payload.body)
        }
    }
}
