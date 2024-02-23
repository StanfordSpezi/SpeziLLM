//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// Represents the configuration of the Spezi ``LLMLocalPlatform``.
public struct LLMLocalPlatformConfiguration: Sendable {
    /// The task priority of the initiated LLM inference tasks.
    let taskPriority: TaskPriority
    /// Indicates if this is a device with non-unified memory access.
    let nonUniformMemoryAccess: Bool
    
    
    /// Creates the ``LLMLocalPlatformConfiguration`` which configures the Spezi ``LLMLocalPlatform``.
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
