//
// This source file is part of the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation

protocol SpeziLLMTask: Identifiable {
    var id: UUID { get async }
    var task: Task<(), Never>? { get async }
    var runnerConfig: SpeziLLMRunnerConfig { get async }
}
