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
    /// Represents the memory limit for the MLX GPU.
    public struct MemoryLimit: Sendable {
        /// The memory limit in MB.
        let limit: Int
        
        /// Calls to malloc will wait on scheduled tasks if the limit is exceeded.  If
        /// there are no more scheduled tasks an error will be raised if `relaxed`
        /// is false or memory will be allocated (including the potential for
        /// swap) if `relaxed` is true.
        ///
        /// The memory limit defaults to 1.5 times the maximum recommended working set
        /// size reported by the device ([recommendedMaxWorkingSetSize](https://developer.apple.com/documentation/metal/mtldevice/2369280-recommendedmaxworkingsetsize))
        let relaxed: Bool
        
        /// Creates the `MemoryLimit` which configures the GPU used by MLX.
        ///
        /// - Parameters:
        ///   - limit: The memory limit in MB.
        ///   - relaxed: See  `relaxed` in ``LLMLocalPlatformConfiguration/MemoryLimit``.
        public init(limit: Int, relaxed: Bool = false) {
            self.limit = limit
            self.relaxed = relaxed
        }
    }
    
    /// The cache limit in MB, to disable set limit to `0`.
    let cacheLimit: Int?
    /// The memory limit for the GPU used by MLX.
    let memoryLimit: MemoryLimit?
    /// The task priority of the initiated LLM inference tasks.
    let taskPriority: TaskPriority
    
    
    /// Creates the ``LLMLocalPlatformConfiguration`` which configures the Spezi ``LLMLocalPlatform``.
    ///
    /// - Parameters:
    ///   - cacheLimit: The cache limit for the GPU used by MLX, defaults to `nil`.
    ///   - memoryLimit: The memory limit for the GPU used by MLX, defaults to `nil`.
    ///   - taskPriority: The task priority of the initiated LLM inference tasks, defaults to `.userInitiated`.
    public init(
        cacheLimit: Int? = nil,
        memoryLimit: MemoryLimit? = nil,
        taskPriority: TaskPriority = .userInitiated
    ) {
        self.cacheLimit = cacheLimit
        self.memoryLimit = memoryLimit
        self.taskPriority = taskPriority
    }
}
