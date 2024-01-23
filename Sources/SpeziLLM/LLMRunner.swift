//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Spezi

/// The ``LLMRunner`` is a Spezi `Module` that handles the execution of Large Language Models (LLMs) in the Spezi ecosystem.
/// A ``LLMRunner`` wraps a Spezi ``LLM`` during it's execution, handling all management overhead tasks of the models execution.
///
/// The ``LLMRunner`` needs to be initialized in the Spezi `Configuration` with the ``LLMRunnerConfiguration`` as well as a set of ``LLMRunnerSetupTask``s as arguments.
///
/// The runner manages a set of ``LLMGenerationTask``'s as well as the respective LLM execution backends in order to enable
/// a smooth and efficient model execution.
///
/// ### Usage
///
/// The code section below showcases a complete code example on how to use the ``LLMRunner`` in combination with a `LLMLocal` (locally executed Language Model) from the [SpeziLLMLocal](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm/spezillmlocal) target.
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
///             ) {
///                 // Runner setup tasks conforming to `LLMRunnerSetupTask` protocol
///                 LLMLocalRunnerSetupTask()
///             }
///         }
///     }
/// }
///
/// struct LocalLLMChatView: View {
///    // The runner responsible for executing the LLM.
///    @Environment(LLMRunner.self) var runner: LLMRunner
///
///    // The executed LLM
///    @State var model: LLMLocal = .init(
///         modelPath: ...
///    )
///    @State var responseText: String
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
public actor LLMRunner: Module, DefaultInitializable, EnvironmentAccessible {
    /// The ``State`` describes the current state of the ``LLMRunner``.
    /// As of now, the ``State`` is quite minimal with only ``LLMRunner/State-swift.enum/idle`` and ``LLMRunner/State-swift.enum/processing`` states.
    public enum State {
        case idle
        case processing
        case error(LocalizedError)
    }
    
    
    /// The configuration of the runner represented by ``LLMRunnerConfiguration``.
    private let runnerConfiguration: LLMRunnerConfiguration
    /// Indicates if the ``LLMRunner`` should lazily perform the passed ``LLMRunnerSetupTask``'s.
    private let lazyRunnerSetup: Bool
    /// Holds all dependencies of the ``LLMRunner`` as expressed by all stated ``LLMRunnerSetupTask``'s in the ``init(runnerConfig:_:)``.
    /// Is required to enable the injection of `Dependency`s into the ``LLMRunnerSetupTask``'s.
    @Dependency private var runnerSetupTaskModules: [any Module]
    /// All to be performed ``LLMRunner``-related setup tasks, mapped to the respective ``LLMHostingType``.
    /// Derived from the ``LLMRunnerSetupTask``'s passed within the ``init(runnerConfig:_:)``.
    private var runnerSetupTasks: [LLMHostingType: any LLMRunnerSetupTask] = [:]
    
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
    ///   - dependencies: A result builder that aggregates all stated ``LLMRunnerSetupTask``'s as dependencies.
    public init(
        runnerConfig: LLMRunnerConfiguration = .init(),
        lazyRunnerSetup: Bool = true,
        @LLMRunnerSetupTaskBuilder _ dependencies: @Sendable () -> DependencyCollection
    ) {
        self.runnerConfiguration = runnerConfig
        self.lazyRunnerSetup = lazyRunnerSetup
        self._runnerSetupTaskModules = Dependency(using: dependencies())
        
        for modelType in LLMHostingType.allCases {
            self.runnerBackendInitialized[modelType] = false
        }
    }
    
    /// Convenience initializer for the creation of a ``LLMRunner``.
    public init() {
        self.init(runnerConfig: .init()) {}
    }
    
    public nonisolated func configure() {
        Task {
            await mapRunnerSetupTasks()
        }
    }
    
    private func mapRunnerSetupTasks() async {
        for module in runnerSetupTaskModules {
            guard let task = module as? any LLMRunnerSetupTask else {
                preconditionFailure("SpeziLLM: Reached inconsistent state. \(type(of: module)) is not a \((any LLMRunnerSetupTask).self)")
            }
            
            runnerSetupTasks[task.type] = task
            
            if !lazyRunnerSetup {
                try? await task.setupRunner(runnerConfig: self.runnerConfiguration)
                runnerBackendInitialized[task.type] = true
            }
        }
    }
    
    
    /// This call-as-a-function ``LLMRunner`` usage wraps a Spezi ``LLM`` and makes it ready for execution.
    /// It manages a set of all ``LLMGenerationTask``'s, guaranteeing efficient model execution.
    ///
    /// - Parameters:
    ///   - with: The ``LLM`` that should be executed.
    ///
    /// - Returns: The ready to use ``LLMGenerationTask``.
    public func callAsFunction(with model: any LLM) async throws -> LLMGenerationTask {
        let modelType = model.type
        /// If necessary, setup of the runner backend
        if runnerBackendInitialized[modelType] != true && modelType != .mock {
            /// Initializes the required runner backends for the respective ``LLMHostingType``.
            guard let task = self.runnerSetupTasks[modelType] else {
                preconditionFailure("""
                    A LLMRunnerSetupTask setting up the runner for a specific LLM environment was not found.
                    Please ensure that a LLMRunnerSetupTask is passed to the Spezi LLMRunner within the Spezi Configuration.
                """)
            }
            
            do {
                try await task.setupRunner(runnerConfig: self.runnerConfiguration)
            } catch {
                // Adjust `LLM/state` to not initialized in order to allow for new errors to surface and trigger and alert
                await MainActor.run {
                    model.state = .uninitialized
                }
                throw error
            }
            
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
    

    /// Upon deinit, cancel all ``LLMRunnerInferenceTask``'s.
    deinit {
        let runnerTasks = runnerTasks
        Task {
            for runnerTask in runnerTasks.values {
                await runnerTask.task?.cancel()
            }
        }
    }
}
