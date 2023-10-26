//
// This source file is part of the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// The ``LLMGenerationTask`` is a `LLMTask` with the specific responsibility to handle LLM generation tasks.
/// It wraps a Spezi ``LLM`` and performs management overhead tasks.
///
/// A code example on how to use ``LLMGenerationTask`` in combination with the ``LLMRunner`` can be
/// found in the documentation of the ``LLMRunner``.
public actor LLMGenerationTask: LLMTask {
    /// The ``LLM`` which is executed by the ``LLMGenerationTask``.
    let model: any LLM
    let runnerConfig: LLMRunnerConfiguration
    var task: Task<(), Never>?
    
    
    var id: LLMTaskIdentifier {
        get async {
            .init(fromModel: model)
        }
    }
    
    /// Describes the state of the ``LLM`` as a ``LLMState``.
    public var state: LLMState {
        get async {
            await self.model.state
        }
    }
    
    
    /// Creates the ``LLMGenerationTask`` based on the respective ``LLM``.
    ///
    /// - Parameters:
    ///   - model: The ``LLM`` that should be executed.
    ///   - runnerConfig: The configuration of the ``LLMRunner``.
    init(model: any LLM, runnerConfig: LLMRunnerConfiguration) {
        self.model = model
        self.runnerConfig = runnerConfig
    }
    
    
    /// Starts the LLM output generation based on an input prompt.
    /// Handles management takes like the initial setup of the ``LLM``.
    ///
    /// - Parameters:
    ///     - prompt: The `String` that should be used as an input to the ``LLM``
    ///
    /// - Returns: An asynchronous stream of the ``LLM`` generation results.
    public func generate(prompt: String) async throws -> AsyncThrowingStream<String, Error> {
        let (stream, continuation) = AsyncThrowingStream.makeStream(of: String.self)
        
        /// Setup the model if necessary.
        if await self.model.state == .uninitialized {
            try await model.setup(runnerConfig: self.runnerConfig)
        }
        
        /// Execute the LLM generation.
        if await model.state == .ready {
            self.task = Task(priority: self.runnerConfig.taskPriority) {
                await model.generate(prompt: prompt, continuation: continuation)
            }
            
            return stream
        }
        
        throw LLMError.modelNotReadyYet
    }
    
    
    /// Upon deinit, cancel the LLM `Task`.
    deinit {
        task?.cancel()
    }
}
