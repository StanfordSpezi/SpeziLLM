//
// This source file is part of the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation


public actor SpeziLLMRunnerInferenceTask: SpeziLLMTask {
    public let id = UUID()
    let model: any SpeziLLMModel
    let runnerConfig: SpeziLLMRunnerConfig
    var task: Task<(), Never>?
    
    
    public var state: SpeziLLMState {
        get async {
            await self.model.state
        }
    }
    
    
    init(model: any SpeziLLMModel, runnerConfig: SpeziLLMRunnerConfig) {
        self.model = model
        self.runnerConfig = runnerConfig
    }
    
    public func generate(prompt: String) async throws -> AsyncThrowingStream<String, Error> {
        let (stream, continuation) = AsyncThrowingStream.makeStream(of: String.self)
        
        if await self.model.state == .uninitialized {
            try await model.setup(runnerConfig: self.runnerConfig)
        }
        
        if await model.state == .ready {
            self.task = Task(priority: self.runnerConfig.taskPriority) {
                await model.generate(prompt: prompt, continuation: continuation)
            }
            
            return stream
        }
        
        throw SpeziLLMError.modelNotReadyYet
    }
    
    
    deinit {
        task?.cancel()
    }
}
