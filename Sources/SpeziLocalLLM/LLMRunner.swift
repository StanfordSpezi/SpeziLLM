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

/// The ``LLMRunner`` is a Spezi `Component` that handles the execution of Large Language Models (LLMs) in the Spezi ecosystem.
/// The runner manages a set of ``LLMGenerationTask``'s as well as the respective backends in order to enable a smooth and efficient
/// model execution.
///
/// A ``LLMRunner`` wraps a Spezi ``LLM`` during it's execution, handling all management overhead tasks of the models execution.
///
/// The ``LLMRunner`` needs to be initialized in the Spezi `Configuration` with the ``LLMRunnerConfiguration``. It should only
/// exist once in the entire application.
///
///
/// The next code section describes a complete example on how to use the ``LLMRunner`` in combination with a ``LLMLlama``.
///
/// ```swift
/// class LocalLLMAppDelegate: SpeziAppDelegate {
///     override var configuration: Configuration {
///         Configuration {
///             // Configure the runner responsible for executing LLMs
///             LLMRunner(
///                 runnerConfig: .init(
///                     taskPriority: .medium
///                 )
///             )
///         }
///     }
/// }
///
///
/// struct LocalLLMChatView: View {
///    // The runner responsible for executing the local LLM.
///    @EnvironmentObject private var runner: LLMRunner
///
///    // The locally executed LLM
///    private let model: LLMLlama = .init(
///         modelPath: ...
///    )
///
///    @State var responseText: String
///
///    ...
///
///    func executePrompt(prompt: String) {
///         // Execute the query on the runner, returning a stream of outputs
///         let stream = try await runner(with: model).generate(prompt: "Hello LLM!")
///
///         for try await token in stream {
///             responseText.append(token)
///        }
///    }
/// }
/// ```
public actor LLMRunner: Component, DefaultInitializable, ObservableObject, ObservableObjectProvider {
    /// The ``State`` describes the current state of the ``LLMRunner``.
    /// As of now, the ``State`` is quite minimal with only ``LLMRunner/State-swift.enum/idle`` and ``LLMRunner/State-swift.enum/processing`` states.
    public enum State {
        case idle
        case processing
    }
    
    
    /// The configuration of the runner represented by ``LLMRunnerConfiguration``.
    private let runnerConfiguration: LLMRunnerConfiguration
    /// Stores all currently available ``LLMGenerationTask``'s, one for each Spezi ``LLM``, identified by the ``LLMTaskIdentifier``.
    private var runnerTasks: [LLMTaskIdentifier: LLMGenerationTask] = [:]
    /// Indicates for which ``LLMHostingType`` the runner backend is already initialized.
    private var runnerBackendInitialized: [LLMHostingType: Bool] = [:]

    /// The ``State`` of the runner, derived from the individual ``LLMGenerationTask``'s.
    @MainActor public var state: State {
        get async {
            var state: State = .idle
            
            for runnerTask in await self.runnerTasks.values where await runnerTask.state == .generating {
                state = .processing
            }
            
            return state
        }
    }
    
    /// Creates the ``LLMRunner`` which is responsible for executing the Spezi ``LLM``'s.
    ///
    /// - Parameters:
    ///   - runnerConfig: The configuration of the ``LLMRunner`` represented by the ``LLMRunnerConfiguration``.
    public init(runnerConfig: LLMRunnerConfiguration) {
        self.runnerConfiguration = runnerConfig
        for modelType in LLMHostingType.allCases {
            self.runnerBackendInitialized[modelType] = false
        }
    }
    
    /// Convenience initializer for the creation of a ``LLMRunner``.
    public init() {
        self.init(runnerConfig: .init())
    }
    
    
    /// This call-as-a-function ``LLMRunner`` usage wraps a Spezi ``LLM`` and makes it ready for execution.
    /// It manages a set of all ``LLMGenerationTask``'s, guaranteeing efficient model execution.
    ///
    /// - Parameters:
    ///   - with: The ``LLM`` that should be executed.
    ///
    /// - Returns: The ready to use ``LLMGenerationTask``.
    public func callAsFunction(with model: any LLM) async -> LLMGenerationTask {
        let modelType = await model.type
        /// If necessary, setup of the runner backend
        if runnerBackendInitialized[modelType] == false {
            await initializeRunnerBackend(for: modelType)
            
            runnerBackendInitialized[modelType] = true
        }
        
        /// Check if a fitting ``LLMRunnerInferenceTask`` for that model already exists
        let taskIdentifier = LLMTaskIdentifier(fromModel: model)
        guard let runnerTask = runnerTasks[taskIdentifier] else {
            let runnerTask = LLMGenerationTask(model: model, runnerConfig: runnerConfiguration)
            runnerTasks[taskIdentifier] = runnerTask
            return runnerTask
        }
        
        return runnerTask
    }
    
    /// Initializes the required runner backends for the respective ``LLMHostingType``.
    private func initializeRunnerBackend(for modelType: LLMHostingType) async {
        switch modelType {
        case .local:
            /// Initialize the llama.cpp backend.
            llama_backend_init(self.runnerConfiguration.numa)
        case .fog:
            break
        case .cloud:
            break
        }
    }
    

    /// Upon deinit, cancel all ``LLMRunnerInferenceTask``'s and free the llama.cpp backend.
    deinit {
        Task {
            for runnerTask in await runnerTasks.values {
                await runnerTask.task?.cancel()
            }
            llama_backend_free()
        }
    }
}
