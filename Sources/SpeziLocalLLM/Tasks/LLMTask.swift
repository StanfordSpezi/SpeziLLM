//
// This source file is part of the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// The `LLMTask` provides an abstraction of different LLM-related `Task`'s.
protocol LLMTask {
    /// Identifier of the `LLMTask`, represented by the ``LLMTaskIdentifier``.
    var id: LLMTaskIdentifier { get async }
    /// The wrapped `Task` executing the model.
    var task: Task<(), Never>? { get async }
    /// The configuration of the ``LLMRunner``.
    var runnerConfig: LLMRunnerConfiguration { get async }
}
