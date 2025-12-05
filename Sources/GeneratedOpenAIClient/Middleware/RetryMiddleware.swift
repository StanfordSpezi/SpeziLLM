//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import HTTPTypes
import OpenAPIRuntime

/// Middleware that retries HTTP requests based on defined conditions.
package struct RetryMiddleware: Sendable {
    /// Signals that trigger evaluation of the retry policy.
    package var signals: Set<RetryableSignal>
    /// Policy that governs retry attempts.
    package var policy: RetryPolicy
    /// Delay strategy applied before each retry.
    package var delay: DelayPolicy

    // MARK: - Initializer

    /// Creates a retry middleware with custom rules.
    ///
    /// - Parameters:
    ///   - signals: Conditions that trigger a retry evaluation, defaults to the typical HTTP 429 and 500s status codes
    ///   - policy: How many times to retry, defaults to 3 attempts.
    ///   - delay: Delay strategy between retries, defaults to exponential backoff with base 1 sec.
    package init(
        signals: Set<RetryableSignal> = [.statusCode(429), .statusRange(500..<600), .onError],
        policy: RetryPolicy = .attempts(3),
        delay: DelayPolicy = .exponential(base: 1)
    ) {
        self.signals = signals
        self.policy = policy
        self.delay = delay
    }
}

// MARK: - Client Middleware Implementation

extension RetryMiddleware: ClientMiddleware {
    package func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        guard case .attempts(let maxAttempts) = policy else {
            return try await next(request, body, baseURL)
        }

        if let body, body.iterationBehavior != .multiple {
            return try await next(request, body, baseURL)
        }

        for attempt in 1...maxAttempts {
            do {
                let (response, responseBody) = try await next(request, body, baseURL)

                if shouldRetry(status: response.status.code) && attempt < maxAttempts {
                    try await pauseBeforeRetry(attempt)
                    continue
                }

                return (response, responseBody)
            } catch {
                if signals.contains(.onError) && attempt < maxAttempts {
                    try await pauseBeforeRetry(attempt)
                    continue
                }

                throw error
            }
        }

        fatalError("Reached unreachable code in retry loop")
    }

    /// Checks if the status code matches any retry conditions.
    private func shouldRetry(status code: Int) -> Bool {
        signals.contains(where: { signal in
            switch signal {
            case .statusCode(let target):
                return code == target
            case .statusRange(let range):
                return range.contains(code)
            case .onError:
                return false
            }
        })
    }

    /// Applies delay before the next retry based on the delay policy.
    private func pauseBeforeRetry(_ attempt: Int) async throws {
        let interval: TimeInterval
        switch delay {
        case .none:
            return
        case .constant(let seconds):
            interval = seconds
        case .exponential(let base):
            interval = base * pow(2, Double(attempt - 1))
        }
        try await Task.sleep(for: .seconds(interval))
    }
}
