//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziChat


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
    
    
    /// Starts the LLM output generation based on the ``LLM/context``.
    /// Handles management takes like the initial setup of the ``LLM``.
    ///
    /// - Returns: An asynchronous stream of the ``LLM`` generation results.
    ///
    /// - Important: This function takes the state present within the ``LLM/context`` to query the ``LLM``. Ensure that the ``LLM/context`` reflects the state you want to use, especially the last (user) entry of the ``LLM/context``.
    public func generate() async throws -> AsyncThrowingStream<String, Error> {
        let (stream, continuation) = AsyncThrowingStream.makeStream(of: String.self)
        
        /// Setup the model if necessary.
        if await self.model.state == .uninitialized {
            try await model.setup(runnerConfig: self.runnerConfig)
        }
        
        /// Execute the output generation of the LLM.
        self.task = Task(priority: self.runnerConfig.taskPriority) {
            await model.generate(continuation: continuation)
        }
        
        return stream
    }
    
    
    /// Starts the LLM output generation based on an input prompt.
    /// Handles management takes like the initial setup of the ``LLM``.
    ///
    /// - Parameters:
    ///     - userPrompt: The `String` that should be used as an input prompt to the ``LLM``
    ///
    /// - Returns: An asynchronous stream of the ``LLM`` generation results.
    ///
    /// - Important: This function appends to the``LLM/context``. Ensure that this wasn't done before by, e.g., the ``LLMChatView``.
    public func generate(prompt userPrompt: String) async throws -> AsyncThrowingStream<String, Error> {
        await MainActor.run {
            self.model.context.append(userInput: userPrompt)
        }
        
        return try await self.generate()
    }
    
    
    /// Upon deinit, cancel the LLM `Task`.
    deinit {
        task?.cancel()
    }
}
