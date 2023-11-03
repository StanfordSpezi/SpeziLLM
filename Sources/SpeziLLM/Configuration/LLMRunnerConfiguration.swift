//
// This source file is part of the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation

/// The ``LLMRunnerConfiguration`` represents the configuration of the Spezi ``LLMRunner``.
public struct LLMRunnerConfiguration: Sendable {
    /// The task priority of the initiated LLM inference tasks.
    public let taskPriority: TaskPriority
    /// Indicates if this is a device with non-unified memory access.
    public let numa: Bool
    
    
    /// Creates the ``LLMRunnerConfiguration`` which configures the Spezi ``LLMRunner``.
    ///
    /// - Parameters:
    ///   - taskPriority: The task priority of the initiated LLM inference tasks, defaults to `.userInitiated`.
    ///   - numa: Indicates if this is a device with non-unified memory access.
    public init(
        taskPriority: TaskPriority = .userInitiated,
        numa: Bool = false
    ) {
        self.taskPriority = taskPriority
        self.numa = numa
    }
}
