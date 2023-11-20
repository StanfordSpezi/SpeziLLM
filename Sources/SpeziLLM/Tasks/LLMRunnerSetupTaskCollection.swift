//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SwiftUI


/// A `_LLMRunnerSetupTaskCollection` defines a collection of Spezi ``LLMRunnerSetupTask``s that are defined with a ``LLMRunner``.
///
/// You can not create a `_LLMRunnerSetupTaskCollection` yourself. Please use the ``LLMRunner`` that internally creates a `_LLMRunnerSetupTaskCollection` with the passed views.
public struct _LLMRunnerSetupTaskCollection {  // swiftlint:disable:this type_name
    let runnerSetupTasks: [LLMHostingType: any LLMRunnerSetupTask]
    
    
    init(runnerSetupTasks: [any LLMRunnerSetupTask]) {
        self.runnerSetupTasks = runnerSetupTasks.reduce(into: [LLMHostingType: any LLMRunnerSetupTask]()) { partialResult, runnerSetupTask in
            /// Check if there are no duplicate ``LLMRunnerSetupTask``'s for the same ``LLMHostingType``.
            guard partialResult[runnerSetupTask.type] == nil else {
                fatalError("""
                LLMRunner was initialized with LLMRunnerSetupTasks's of the same LLMHostingType type.
                Ensure that only one LLMRunnerSetupTask is responsible for setting up the runner of one LLMHostingType.
                """)
            }
            
            partialResult[runnerSetupTask.type] = runnerSetupTask
        }
    }
}
