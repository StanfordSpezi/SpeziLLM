//
// This source file is part of the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
import llama
import Spezi

public actor SpeziLLMRunner: Component, DefaultInitializable, ObservableObject, ObservableObjectProvider {
    public enum RunnerState {
        case idle
        case processing
        case erorr
    }
    
    private let runnerConfig: SpeziLLMRunnerConfig
    private var runnerTasks: [SpeziLLMTaskIdentifier: SpeziLLMRunnerInferenceTask] = [:]
    private var runnerBackendInitialized: [SpeziLLMModelType: Bool] = [:]

    
    @MainActor public var state: RunnerState {
        get async {
            var state: RunnerState = .idle
            
            for runnerTask in await self.runnerTasks.values where await runnerTask.state == .inferring {
                state = .processing
            }
            
            return state
        }
    }
    
    
    public init(runnerConfig: SpeziLLMRunnerConfig) {
        self.runnerConfig = runnerConfig
        for modelType in SpeziLLMModelType.allCases {
            self.runnerBackendInitialized[modelType] = false
        }
    }
    
    public init() {
        self.init(runnerConfig: .init())
    }
    
    
    public func callAsFunction(with model: any SpeziLLMModel) async -> SpeziLLMRunnerInferenceTask {
        let modelType = await model.type
        if runnerBackendInitialized[modelType] == false {
            // Setup of the runner (if necessary)
            await initializeRunnerBackend(for: modelType)
            
            runnerBackendInitialized[modelType] = true
        }
        
        // Check if a fitting LLM task with that model already exists
        let taskIdentifier = SpeziLLMTaskIdentifier(fromModel: model)
        guard let runnerTask = runnerTasks[taskIdentifier] else {
            let runnerTask = SpeziLLMRunnerInferenceTask(model: model, runnerConfig: runnerConfig)
            runnerTasks[taskIdentifier] = runnerTask
            return runnerTask
        }
        
        return runnerTask
    }
    
    private func initializeRunnerBackend(for modelType: SpeziLLMModelType) async {
        switch modelType {
        case .local:
            llama_backend_init(self.runnerConfig.numa)
        case .fog:
            break
        case .cloud:
            break
        }
    }
    
    // TODO: Captures runnerTasks reference after deinit?
    deinit {
        Task {
            for runnerTask in await runnerTasks.values {
                await runnerTask.task?.cancel()
            }
            llama_backend_free()
        }
    }
}
