//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import llama


/// Represents the configuration of the Spezi ``LLMLocalPlatform``.
public struct LLMLocalPlatformConfiguration: Sendable {
    /// Wrapper around the `ggml_numa_strategy` type of llama.cpp, indicating the non-unified memory access configuration of the device.
    public enum NonUniformMemoryAccess: UInt32, Sendable {
        case disabled
        case distributed
        case isolated
        case numaCtl
        case mirror
        case count
        
        
        var wrappedValue: ggml_numa_strategy {
            .init(rawValue: self.rawValue)
        }
    }
    
    
    /// The task priority of the initiated LLM inference tasks.
    let taskPriority: TaskPriority
    /// Indicates the non-unified memory access configuration of the device.
    let nonUniformMemoryAccess: NonUniformMemoryAccess
    
    
    /// Creates the ``LLMLocalPlatformConfiguration`` which configures the Spezi ``LLMLocalPlatform``.
    ///
    /// - Parameters:
    ///   - taskPriority: The task priority of the initiated LLM inference tasks, defaults to `.userInitiated`.
    ///   - nonUniformMemoryAccess: Indicates if this is a device with non-unified memory access.
    public init(
        taskPriority: TaskPriority = .userInitiated,
        nonUniformMemoryAccess: NonUniformMemoryAccess = .disabled
    ) {
        self.taskPriority = taskPriority
        self.nonUniformMemoryAccess = nonUniformMemoryAccess
    }
}
