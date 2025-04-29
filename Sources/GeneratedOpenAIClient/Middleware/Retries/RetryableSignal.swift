//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

/// Conditions under which a request should be retried.
public enum RetryableSignal: Hashable, Sendable {
    /// Retry when response status matches this code.
    case statusCode(Int)
    /// Retry when status falls within this range.
    case statusRange(Range<Int>)
    /// Retry when an error is thrown by downstream middleware or transport.
    case onError
}
