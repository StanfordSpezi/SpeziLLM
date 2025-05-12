//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

/// Determines how many times to retry.
public enum RetryPolicy: Hashable, Sendable {
    /// Never retry.
    case never
    /// Retry up to the specified number of attempts.
    case attempts(Int)
}
