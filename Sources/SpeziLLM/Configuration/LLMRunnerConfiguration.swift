//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation

/// The ``LLMRunnerConfiguration`` represents the configuration of the Spezi ``LLMRunner``.
public struct LLMRunnerConfiguration: Sendable {
    /// The task priority of the initiated LLM inference tasks.
    public let taskPriority: TaskPriority
    /// Indicates if this is a device with non-unified memory access.
    public let nonUniformMemoryAccess: Bool
    
    
    /// Creates the ``LLMRunnerConfiguration`` which configures the Spezi ``LLMRunner``.
    ///
    /// - Parameters:
    ///   - taskPriority: The task priority of the initiated LLM inference tasks, defaults to `.userInitiated`.
    ///   - nonUniformMemoryAccess: Indicates if this is a device with non-unified memory access.
    public init(
        taskPriority: TaskPriority = .userInitiated,
        nonUniformMemoryAccess: Bool = false
    ) {
        self.taskPriority = taskPriority
        self.nonUniformMemoryAccess = nonUniformMemoryAccess
    }
}
