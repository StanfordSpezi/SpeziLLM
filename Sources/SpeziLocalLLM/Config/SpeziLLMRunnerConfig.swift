//
// This source file is part of the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation


public struct SpeziLLMRunnerConfig: Sendable {
    let taskPriority: TaskPriority
    let numa: Bool
    
    
    public init(
        taskPriority: TaskPriority = .userInitiated,
        numa: Bool = false
    ) {
        self.taskPriority = taskPriority
        self.numa = numa
    }
}
