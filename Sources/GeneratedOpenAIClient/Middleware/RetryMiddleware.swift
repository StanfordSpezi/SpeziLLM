//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import OpenAPIRuntime
import Foundation
import HTTPTypes

/// Middleware that retries HTTP requests based on defined conditions.
package struct RetryMiddleware {

    // MARK: - Retry Signals

    /// Conditions under which a request should be retried.
    package enum RetryableSignal: Hashable {
        /// Retry when response status matches this code.
        case statusCode(Int)
        /// Retry when status falls within this range.
        case statusRange(Range<Int>)
        /// Retry when an error is thrown by downstream middleware or transport.
        case onError
    }

    // MARK: - Retry Policy

    /// Determines how many times to retry.
    package enum RetryingPolicy: Hashable {
        /// Never retry.
        case never
        /// Retry up to the specified number of attempts.
        case attempts(Int)
    }

    // MARK: - Delay Policy

    /// Defines delay between retries.
    package enum DelayPolicy: Hashable {
        /// No delay; retry immediately.
        case none
        /// Pause for a fixed number of seconds before retry.
        case constant(TimeInterval)
    }

    // MARK: - Configuration Properties

    /// Signals that trigger evaluation of the retry policy.
    package var signals: Set<RetryableSignal>
    /// Policy that governs retry attempts.
    package var policy: RetryingPolicy
    /// Delay applied before each retry.
    package var delay: DelayPolicy


    /// Creates a retry middleware with custom rules.
    ///
    /// - Parameters:
    ///   - signals: Conditions that trigger a retry evaluation.
    ///   - policy: How many times to retry.
    ///   - delay: Delay strategy between retries.
    package init(
        signals: Set<RetryableSignal> = [.statusCode(429), .statusRange(500..<600), .onError],
        policy: RetryingPolicy = .attempts(3),
        delay: DelayPolicy = .constant(1)
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
                    try await pauseBeforeRetry()
                    continue
                }

                return (response, responseBody)

            } catch {
                if signals.contains(.onError) && attempt < maxAttempts {
                    try await pauseBeforeRetry()
                    continue
                }
                throw error
            }
        }

        preconditionFailure("Reached unreachable code in retry loop")
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

    /// Applies delay before the next retry.
    private func pauseBeforeRetry() async throws {
        switch delay {
        case .none:
            return
        case .constant(let seconds):
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        }
    }
}
