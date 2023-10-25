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


public class SpeziLocalLLMRunner: Component, DefaultInitializable, ObservableObject, ObservableObjectProvider {
    @Published public var state: SpeziLLMModelState = .idle
    
    private let taskPriority: TaskPriority
    private let runnerConfig: SpeziLLMRunnerConfig
    private var task: Task<(), Never>?
    
    
    public init(taskPriority: TaskPriority, runnerConfig: SpeziLLMRunnerConfig) {
        self.taskPriority = taskPriority
        self.runnerConfig = runnerConfig
    }
    
    public required convenience init() {
        self.init(taskPriority: .userInitiated, runnerConfig: .init())
    }
    
    
    public func configure() {
        llama_backend_init(runnerConfig.numa)
    }
}
