//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation

/// Defines delay between retries.
public enum DelayPolicy: Hashable, Sendable {
    /// No delay; retry immediately.
    case none
    /// Fixed pause before each retry.
    case constant(TimeInterval)
    /// Binary exponential backoff using a base interval.
    case exponential(base: TimeInterval)
}
