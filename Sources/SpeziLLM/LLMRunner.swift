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
/// For one-shot LLM inference tasks, the ``LLMRunner`` provides ``LLMRunner/oneShot(with:chat:)-2a1du`` and ``LLMRunner/oneShot(with:chat:)-24coq``, enabling the ``LLMRunner`` to deal with the LLM state management and reducing the burden on developers by just returning an `AsyncThrowingStream` or `String` directly.
///
/// ### Usage
///
/// The code section below showcases a complete, bare-bone code example on how to use the ``LLMRunner`` with the ``LLMSchema``.
/// The example is structured as a SwiftUI `View` with a `Button` to trigger LLM inference via the ``LLMMockSchema``. The generated output stream is displayed in a `Text` field.
///
/// - Tip: SpeziLLM provides the `@LLMSessionProvider` property wrapper (`View/LLMSessionProvider`) that drastically simplifies the state management of using the ``LLMSchema`` with the ``LLMRunner``. Refer to the docs for more information.
///
/// ```swift
/// struct LLMDemoView: View {
///     // The runner responsible for executing the LLM.
///     @Environment(LLMRunner.self) var runner
///
///     // The LLM in execution, as defined by the ``LLMSchema``.
///     @State var llmSession: LLMMockSession?
///     @State var responseText = ""
///
///     var body: some View {
///         VStack {
///             Button {
///                 Task {
///                     try await executePrompt(prompt: "Hello LLM!")
///                 }
///             } label: {
///                 Text("Start LLM inference")
///             }
///                 .disabled(if: llmSession)
///
///             Text(responseText)
///         }
///             .task {
///                 // Instantiate the `LLMSchema` to an `LLMSession` via the `LLMRunner`.
///                 self.llmSession = runner(with: LLMMockSchema())
///             }
///     }
///
///     func executePrompt(prompt: String) async throws {
///         await MainActor.run {
///             llmSession?.context.append(userInput: prompt)
///         }
///
///         // Performing the LLM inference, returning a stream of outputs.
///         guard let stream = try await llmSession?.generate() else {
///             return
///         }
///
///         for try await token in stream {
///             responseText.append(token)
///         }
///    }
/// }
/// ```
public class LLMRunner: Module, EnvironmentAccessible, DefaultInitializable {
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
        var state: State = .idle
        
        for platform in self.llmPlatforms.values where platform.state == .processing {
            state = .processing
        }
        
        return state
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
    
    /// Convenience initializer for the creation of an ``LLMRunner`` that doesn't support any ``LLMPlatform``s
    /// Helpful for stating a Spezi `Dependency` to the ``LLMRunner``.
    public required convenience init() {
        self.init {}
    }
    
    
    public func configure() {
        self.llmPlatforms = _llmPlatformModules.wrappedValue.compactMap { platform in
            platform as? (any LLMPlatform)
        }
        .reduce(into: [:]) { partialResult, platform in
            partialResult[platform.schemaId] = platform
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
    public func callAsFunction<L: LLMSchema>(with llmSchema: L) -> L.Platform.Session {
        // Searches for the respective `LLMPlatform` associated with the `LLMSchema`.
        guard let platform = llmPlatforms[ObjectIdentifier(L.self)] else {
            preconditionFailure("""
            The designated `LLMPlatform` \(String(describing: L.Platform.Session.self)) to run the `LLMSchema` \(String(describing: L.self)) was not configured within the Spezi `Configuration`.
            Ensure that the `LLMRunner` is set up with all required `LLMPlatform`s.
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
        return platform.determinePlatform(for: llmSchema)
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
        let llmSession = callAsFunction(with: llmSchema)
        await MainActor.run {
            llmSession.context = chat
        }
        
        return try await llmSession.generate()
    }
    
    /// One-shot mechanism to turn the received ``LLMSchema`` into a completed output `String`.
    ///
    /// Directly returns the finished output `String` based on the defined ``LLMSchema`` as well as the passed `Chat` (context of the LLM).
    ///
    /// - Parameters:
    ///   - with: The ``LLMSchema`` that should be turned into an ``LLMSession``.
    ///   - chat: The context of the LLM used for the inference.
    ///
    /// - Returns: The completed output `String`.
    public func oneShot<L: LLMSchema>(with llmSchema: L, chat: Chat) async throws -> String {
        var output = ""
        
        for try await stringPiece in try await oneShot(with: llmSchema, chat: chat) {
            output.append(stringPiece)
        }
        
        return output
    }
}

extension LLMPlatform {
    /// Determine the correct ``LLMPlatform`` for the passed ``LLMSchema``.
    fileprivate func determinePlatform<L: LLMSchema>(for schema: L) -> L.Platform.Session {
        guard let schema = schema as? Schema else {
            preconditionFailure("""
            Reached inconsistent state. Ensure that the specified LLMSchema matches the schema defined within the LLMPlatform.
            """)
        }
        
        guard let session = self(with: schema) as? L.Platform.Session else {
            preconditionFailure("""
            Reached inconsistent state. Ensure that the specified LLMSession matches the session defined within the LLMPlatform.
            """)
        }
        
        return session
    }
}
