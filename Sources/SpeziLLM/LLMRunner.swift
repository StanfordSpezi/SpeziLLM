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

/// Manages the execution of LLMs in the Spezi ecosystem.
///
/// The ``LLMRunner`` is a Spezi `Module` available for access through the SwiftUI `Environment` that is responsible for turning a ``LLMSchema`` towards an executable and stateful ``LLMSession``.
/// The ``LLMRunner`` delegates the creation of the ``LLMSession``s to the respective ``LLMPlatform``s, allowing for customized creation and dependency injection for each LLM type.
///
/// Within the Spezi ecosystem, the ``LLMRunner`` is set up via the Spezi `Configuration` by taking a trailing closure argument within ``LLMRunner/init(_:)``.
/// The closure aggregates multiple stated ``LLMPlatform``s via is the ``LLMPlatformBuilder``, enabling easy and dynamic configuration of all wanted ``LLMPlatform``s.
///
/// The main functionality of the ``LLMRunner`` is``LLMRunner/callAsFunction(with:)``, turning a ``LLMSchema`` to an executable ``LLMSession`` via the respective ``LLMPlatform``.
/// The created ``LLMSession`` then holds the LLM context and is able to perform the actual LLM inference.
/// For one-shot LLM inference tasks, the ``LLMRunner`` provides ``LLMRunner/oneShot(with:chat:)``, enabling the ``LLMRunner`` to deal with the LLM state management and reducing the burden on developers by just returning an `AsyncThrowingStream`.
///
/// ### Usage
///
/// The code section below showcases a complete code example on how to use the ``LLMRunner`` in combination with a ``LLMChatView``.
///
/// ```swift
/// class LLMAppDelegate: SpeziAppDelegate {
///     override var configuration: Configuration {
///         Configuration {
///             // Configure the runner with the respective `LLMPlatform`s
///             LLMRunner {
///                 LLMMockPlatform()
///             }
///         }
///     }
/// }
///
/// struct LLMChatView: View {
///     var body: some View {
///         LLMChatView(
///             schema: LLMMockSchema()
///         )
///     }
/// }
/// ```
public actor LLMRunner: Module, EnvironmentAccessible {
    /// The ``State`` describes the current state of the ``LLMRunner``.
    /// As of now, the ``State`` is quite minimal with only ``LLMRunner/State-swift.enum/idle`` and ``LLMRunner/State-swift.enum/processing`` states.
    public enum State {
        case idle
        case processing
    }
    

    /// Holds all configured ``LLMPlatform``s of the ``LLMRunner`` as expressed by all stated ``LLMPlatform``'s in the ``LLMRunner/init(_:)``.
    @Dependency private var llmPlatformModules: [any Module]
    /// Maps the ``LLMSchema`` (identified by the `ObjectIdentifier`) towards the respective ``LLMPlatform``.
    var llmPlatforms: [ObjectIdentifier: any LLMPlatform] = [:]

    /// The ``State`` of the runner, derived from the individual ``LLMPlatform``'s.
    @MainActor public var state: State {
        get async {
            var state: State = .idle
            
            for platform in await self.llmPlatforms.values where platform.state == .processing {
                state = .processing
            }
            
            return state
        }
    }
    
    /// Creates the ``LLMRunner`` which is responsible for executing LLMs within the Spezi ecosystem.
    ///
    /// - Parameters:
    ///   - dependencies: A result builder that aggregates all stated ``LLMPlatform``s.
    public init(
        @LLMPlatformBuilder _ dependencies: @Sendable () -> DependencyCollection
    ) {
        self._llmPlatformModules = Dependency(using: dependencies())
    }
    
    
    public nonisolated func configure() {
        Task {
            await mapLLMPlatformModules()
        }
    }
    
    /// Turns the received ``LLMSchema`` to an executable ``LLMSession``.
    ///
    /// The ``LLMRunner`` uses the configured ``LLMPlatform``s to create an executable ``LLMSession`` from the passed ``LLMSchema``
    ///
    /// - Parameters:
    ///   - with: The ``LLMSchema`` that should be turned into an ``LLMSession``.
    ///
    /// - Returns: The ready to use ``LLMSession``.
    public func callAsFunction<L: LLMSchema>(with llmSchema: L) async -> L.Platform.Session {
        // Searches for the respective `LLMPlatform` associated with the `LLMSchema`.
        guard let platform = llmPlatforms[ObjectIdentifier(L.self)] else {
            preconditionFailure("""
            The designated `LLMPlatform` to run the `LLMSchema` was not configured within the Spezi `Configuration`.
            Ensure that the `LLMRunner` is set up with all required `LLMPlatform`s
            """)
        }
        
        // Checks the conformance of the related `LLMSession` to `Observable`.
        guard L.Platform.Session.self is Observable.Type else {
            preconditionFailure("""
            The passed `LLMSchema` \(String(describing: L.self)) corresponds to a not observable `LLMSession` type (found session was \(String(describing: L.Platform.Session.self))).
            Ensure that the used `LLMSession` type (\(String(describing: L.Platform.Session.self))) conforms to the `Observable` protocol via the `@Observable` macro.
            """)
        }
        
        // Delegates the creation of the `LLMSession` to the configured `LLMPlatform`s.
        return await platform.callFunction(with: llmSchema)
    }
    
    /// One-shot mechanism to turn the received ``LLMSchema`` into an `AsyncThrowingStream`.
    ///
    /// Directly returns an `AsyncThrowingStream` based on the defined ``LLMSchema`` as well as the passed `Chat` (context of the LLM).
    ///
    /// - Parameters:
    ///   - with: The ``LLMSchema`` that should be turned into an ``LLMSession``.
    ///   - chat: The context of the LLM used for the inference.
    ///
    /// - Returns: The ready to use `AsyncThrowingStream`.
    public func oneShot<L: LLMSchema>(with llmSchema: L, chat: Chat) async throws -> AsyncThrowingStream<String, Error> {
        let llmSession = await callAsFunction(with: llmSchema)
        await MainActor.run {
            llmSession.context = chat
        }
        
        return try await llmSession.generate()
    }
    
    /// Maps the ``LLMPlatform``s to the ``LLMSchema``s.
    private func mapLLMPlatformModules() {
        self.llmPlatforms = _llmPlatformModules.wrappedValue.compactMap { platform in
            platform as? (any LLMPlatform)
        }
        .reduce(into: [:]) { partialResult, platform in
            partialResult[platform.schemaId] = platform
        }
    }
}

extension LLMPlatform {
    /// Delegation in order to use the correct ``LLMPlatform`` for the passed ``LLMSchema``.
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
