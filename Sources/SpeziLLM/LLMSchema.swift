//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

/// Defines the type and configuration of the LLM.
///
/// The ``LLMSchema`` is used as a configuration for a to-be-used LLM. It should contain all necessary values for the creation of a ``LLMSession``.
/// It is bound to a ``LLMPlatform`` that is responsible for turning the ``LLMSchema`` to an ``LLMSession``.
///
/// - Tip: The ``LLMSchema`` should be implemented as a Swift `struct`, immutable and easily copyable.
///
/// ### Usage
///
/// The example below demonstrates a concrete implementation of the ``LLMSchema`` with the ``LLMMockPlatform``.
///
/// ```
/// public struct LLMMockSchema: LLMSchema {
///     public typealias Platform = LLMMockPlatform
///
///     public let injectIntoContext = false
///
///     public init() {}
/// }
/// ```
public protocol LLMSchema {
    associatedtype Platform: LLMPlatform
    
    
    /// Indicates if the inference output by the ``LLMSession`` should automatically be inserted into the ``LLMSession/context``.
    var injectIntoContext: Bool { get }
}
