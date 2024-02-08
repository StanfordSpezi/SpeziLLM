//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Spezi


/// LLM execution platform of an ``LLMSchema``.
///
/// The ``LLMPlatform`` is responsible for turning the received ``LLMSchema`` (describing the type and configuration of the LLM) to an executable ``LLMSession``.
/// The ``LLMPlatform`` is bound to a single ``LLMSchema`` as well as a single ``LLMSession``, so a 1:1 relation of all these components.
///
/// Use ``LLMPlatform/callAsFunction(with:)`` with an ``LLMSchema`` parameter to get an executable ``LLMSession`` that does the actual inference.
/// ``LLMPlatform/state`` indicates if the ``LLMPlatform`` is currently ``LLMPlatformState/idle`` or ``LLMPlatformState/processing``.
///
/// We enforce the implementation of the ``LLMPlatform`` as a [Swift Actor](https://developer.apple.com/documentation/swift/actor), ensuring concurrency-proof execution of the LLM.
///
/// - Important: ``LLMPlatform``s shouldn't be used directly but used via the ``LLMRunner`` that delegates the requests towards the specific ``LLMPlatform``.
/// The ``LLMRunner`` must be configured with all to-be-supported ``LLMPlatform``s within the Spezi `Configuration`.
///
/// - Tip: The ``LLMPlatform`` is a Spezi `Module`, enabling to use the full power of the Spezi `Dependency` and `Module` mechanisms.
///
/// ### Usage
///
/// The example below demonstrates a concrete implementation of the ``LLMPlatform`` with the ``LLMMockSchema`` and ``LLMMockSession``.
///
/// ```swift
/// public actor LLMMockPlatform: LLMPlatform {
///     @MainActor public let state: LLMPlatformState = .idle
///
///     public init() {}
///
///     public func callAsFunction(with: LLMMockSchema) async -> LLMMockSession {
///         LLMMockSession(self, schema: with)
///     }
/// }
/// ```
public protocol LLMPlatform: Module, EnvironmentAccessible, AnyActor {
    /// The ``LLMSchema`` that is bound to the ``LLMPlatform``.
    associatedtype Schema: LLMSchema
    /// The ``LLMSession`` that is created from the ``LLMSchema`` by the ``LLMPlatform``.
    associatedtype Session: LLMSession
    
    
    /// Describes the state of the ``LLMPlatform`` via the ``LLMPlatformState``.
    @MainActor var state: LLMPlatformState { get }
    
    
    /// Turns the received ``LLMSchema`` to an executable ``LLMSession``.
    ///
    /// The ``LLMPlatform`` uses the ``LLMSchema`` to create an ``LLMSession`` that performs the LLM inference and contains the LLM context.
    ///
    /// - Parameters:
    ///   - with: The ``LLMSchema`` that should be turned into an ``LLMSession``.
    ///
    /// - Returns: The ready to use ``LLMSession``.
    func callAsFunction(with: Schema) async -> Session
}


extension LLMPlatform {
    /// Enables the identification of the ``LLMPlatform/Schema`` via an `ObjectIdentifier`.
    var schemaId: ObjectIdentifier {
        ObjectIdentifier(Schema.self)
    }
}
