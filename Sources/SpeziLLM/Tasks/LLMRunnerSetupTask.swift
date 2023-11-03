//
// This source file is part of the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// The ``LLMRunnerSetupTask`` provides an abstraction of different runner-related setup `Task`'s.
public protocol LLMRunnerSetupTask {
    /// The ``LLMHostingType`` that the ``LLMRunnerSetupTask`` sets up.
    var type: LLMHostingType { get }
    
    
    /// Performs runner setup-related actions for the ``LLMRunner``.
    func setupRunner(runnerConfig: LLMRunnerConfiguration) async throws
}
