//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// Configuration for the ``LLMFoundationModelsPlatform``.
public struct LLMFoundationModelsPlatformConfiguration: Sendable {
    /// Priority of dispatched inference tasks.
    public let taskPriority: TaskPriority

    /// Creates a new platform configuration.
    /// - Parameter taskPriority: Priority of dispatched inference tasks. Defaults to `.userInitiated`.
    public init(taskPriority: TaskPriority = .userInitiated) {
        self.taskPriority = taskPriority
    }
}
