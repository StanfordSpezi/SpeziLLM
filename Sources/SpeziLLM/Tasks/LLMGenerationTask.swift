//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// The ``LLMGenerationTask`` with the specific responsibility to handle LLM generation tasks.
/// It wraps a Spezi ``LLM`` and performs management overhead tasks.
///
/// A code example on how to use ``LLMGenerationTask`` in combination with the ``LLMRunner`` can be
/// found in the documentation of the ``LLMRunner``.
public actor LLMGenerationTask {
    /// The ``LLM`` which is executed by the ``LLMGenerationTask``.
    let model: any LLM
    /// The configuration of the ``LLMRunner``.
    let runnerConfig: LLMRunnerConfiguration
    /// A task managing the ``LLM` output generation.
    var task: Task<(), Never>?
    
    
    /// The `LLMTaskIdentifier` of the ``LLMGenerationTask``.
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
        switch await model.state {
        case .ready, .error:
            self.task = Task(priority: self.runnerConfig.taskPriority) {
                await model.generate(prompt: prompt, continuation: continuation)
            }
            
            return stream
        default:
            throw LLMError.modelNotReadyYet
        }
    }
    
    
    /// Upon deinit, cancel the LLM `Task`.
    deinit {
        task?.cancel()
    }
}
