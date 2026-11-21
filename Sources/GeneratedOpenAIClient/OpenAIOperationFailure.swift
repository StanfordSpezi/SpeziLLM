//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import OpenAPIRuntime


/// A response other than the documented success: the status code the server answered with, and its raw body.
///
/// The preprocessing script removes every failure response from the document, so failures are never decoded by the
/// generated client. OpenAI-compatible servers and the proxies in front of fog nodes answer with error bodies of their
/// own, and decoding them as OpenAI's shape would turn a `401` or `503` into a decoding error.
package struct OpenAIOperationFailure: Sendable {
    /// The HTTP status code the server answered with.
    package let statusCode: Int
    /// The raw body of the response, if it had one.
    package let body: HTTPBody?


    package init(statusCode: Int, body: HTTPBody? = nil) {
        self.statusCode = statusCode
        self.body = body
    }


    static func message(from data: Data) -> String? {
        if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let error = object["error"] as? [String: Any], let message = error["message"] as? String, !message.isEmpty {
                return message
            }
            if let message = object["error"] as? String, !message.isEmpty {
                return message
            }
        }
        guard let text = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            return nil
        }
        return text
    }


    /// Reads the body and returns the message it carries.
    ///
    /// OpenAI and most compatible servers send `{"error": {"message": …}}`, and some send `{"error": "…"}`; the message
    /// is taken from either. Any other body is returned as text. The body can only be read once.
    ///
    /// - Parameter limit: The most bytes to read from the body.
    /// - Returns: The message, or `nil` if the body is missing, empty, or not text.
    package func message(upTo limit: Int = 8 * 1024) async -> String? {
        guard let body, let data = try? await Data(collecting: body, upTo: limit) else {
            return nil
        }
        return Self.message(from: data)
    }
}


extension Operations.createChatCompletion.Output {
    /// The failure this response reports, or `nil` for the documented success.
    package var failure: OpenAIOperationFailure? {
        switch self {
        case .ok:
            nil
        case let .undocumented(statusCode, payload):
            .init(statusCode: statusCode, body: payload.body)
        }
    }
}


extension Operations.createResponse.Output {
    /// The failure this response reports, or `nil` for the documented success.
    package var failure: OpenAIOperationFailure? {
        switch self {
        case .ok:
            nil
        case let .undocumented(statusCode, payload):
            .init(statusCode: statusCode, body: payload.body)
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
            .init(statusCode: statusCode, body: payload.body)
        }
    }
}
