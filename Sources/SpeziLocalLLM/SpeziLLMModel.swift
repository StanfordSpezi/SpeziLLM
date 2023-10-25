//
// This source file is part of the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation


public protocol SpeziLLMModel {
    var type: SpeziLLMModelType { get async }
    var state: SpeziLLMState { get async }
    
    func setup(runnerConfig: SpeziLLMRunnerConfig) async throws
    
    func generate(prompt: String, continuation: AsyncThrowingStream<String, Error>.Continuation) async
}
