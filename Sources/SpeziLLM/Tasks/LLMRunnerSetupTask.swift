//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// The ``LLMRunnerSetupTask`` provides an abstraction of different runner-related setup `Task`'s.
/// These setup tasks must be stated within the Spezi ``LLMRunner`` initializer in order to properly configure the local environment for executing Spezi `LLM`s.
/// 
/// ```swift
/// class LLMAppDelegate: SpeziAppDelegate {
///     override var configuration: Configuration {
///         Configuration {
///             LLMRunner {
///                 // Concrete `LLMRunnerSetupTask`s
///                 ...
///             }
///         }
///     }
/// }
public protocol LLMRunnerSetupTask {
    /// The ``LLMHostingType`` that the ``LLMRunnerSetupTask`` sets up.
    var type: LLMHostingType { get }
    
    
    /// Performs runner setup-related actions for the ``LLMRunner``.
    func setupRunner(runnerConfig: LLMRunnerConfiguration) async throws
}
