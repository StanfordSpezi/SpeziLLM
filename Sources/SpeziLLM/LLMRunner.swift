//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Spezi
import SpeziChat

/// Handles the execution of Large Language Models (LLMs) in the Spezi ecosystem.
///
/// The ``LLMRunner`` is a Spezi `Module` that that wraps a Spezi ``LLM`` during it's execution, handling all management overhead tasks of the models execution.
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
///
///             ) {
///                 // Runner setup tasks conforming to `LLMRunnerSetupTask` protocol
///                 // LLMLocalRunnerSetupTask()
///                 LLMLocalPlatform(taskPriority: .useInitated)
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
public actor LLMRunner: Module, EnvironmentAccessible {
    /// The ``State`` describes the current state of the ``LLMRunner``.
    /// As of now, the ``State`` is quite minimal with only ``LLMRunner/State-swift.enum/idle`` and ``LLMRunner/State-swift.enum/processing`` states.
    public enum State {
        case idle
        case processing
    }
    

    /// Holds all dependencies of the ``LLMRunner`` as expressed by all stated ``LLMRunnerSetupTask``'s in the ``init(runnerConfig:_:)``.
    /// Is required to enable the injection of `Dependency`s into the ``LLMRunnerSetupTask``'s.
    @Dependency private var llmPlatformModules: [any Module]
    
    var llmPlatforms: [ObjectIdentifier: any LLMPlatform] = [:]

    /// The ``State`` of the runner, derived from the individual ``LLMGenerationTask``'s.
    @MainActor public var state: State {
        get async {
            var state: State = .idle
            
            for platform in await self.llmPlatforms.values where platform.state == .processing {
                state = .processing
            }
            
            return state
        }
    }
    
    /// Creates the ``LLMRunner`` which is responsible for executing the Spezi ``LLM``'s.
    ///
    /// - Parameters:
    ///   - dependencies: A result builder that aggregates all stated ``LLMRunnerSetupTask``'s as dependencies.
    public init(
        @LLMRunnerPlatformBuilder _ dependencies: @Sendable () -> DependencyCollection
    ) {
        self._llmPlatformModules = Dependency(using: dependencies())
    }
    
    
    public nonisolated func configure() {
        Task {
            await mapModules()
        }
    }
    
    /// This call-as-a-function ``LLMRunner`` usage wraps a Spezi ``LLM`` and makes it ready for execution.
    /// It manages a set of all ``LLMGenerationTask``'s, guaranteeing efficient model execution.
    ///
    /// - Parameters:
    ///   - with: The ``LLM`` that should be executed.
    ///
    /// - Returns: The ready to use ``LLMGenerationTask``.
    public func callAsFunction<L: LLMSchema>(with llmSchema: L) async -> L.Platform.Session {
        guard let platform = llmPlatforms[ObjectIdentifier(L.self)] else {
            preconditionFailure("""
            The designated `LLMPlatform` to run the `LLMSchema` was not configured within the Spezi `Configuration`.
            Ensure that the `LLMRunner` is set up with all required `LLMPlatform`s
            """)
        }
        
        guard L.Platform.Session.self as? Observable.Type != nil else {
            preconditionFailure("""
            The passed `LLMSchema` corresponds to a not observable `LLMSession` type.
            Ensure that the used `LLMSession` type conforms to the `Observable` protocol via the `@Observable` macro.
            """)
        }
        
        return await platform.callFunction(with: llmSchema)
    }
    
    /// One-shot schema, directly returns a stream (no possible follow up as we don't hand out the session!)
    public func oneShot<L: LLMSchema>(with llmSchema: L, chat: Chat) async throws -> AsyncThrowingStream<String, Error> {
        let llmSession = await callAsFunction(with: llmSchema)
        await MainActor.run {
            llmSession.context = chat
        }
        
        return try await llmSession.generate()
    }
    
    private func mapModules() {
        self.llmPlatforms = _llmPlatformModules.wrappedValue.compactMap { platform in
            platform as? (any LLMPlatform)
        }
        .reduce(into: [:]) { partialResult, platform in
            partialResult[platform.schemaId] = platform
        }
    }
}

extension LLMPlatform {
    fileprivate func callFunction<L: LLMSchema>(with schema: L) async -> L.Platform.Session {
        guard let schema = schema as? Schema else {
            preconditionFailure("""
            Reached inconsistent state. Ensure that the specified LLMSchema matches the schema defined within the LLMPlatform.
            """)
        }
        
        guard let session = await self(with: schema) as? L.Platform.Session else {
            preconditionFailure("""
            Reached inconsistent state. Ensure that the specified LLMSession matches the session defined within the LLMPlatform.
            """)
        }
        
        return session
    }
}
