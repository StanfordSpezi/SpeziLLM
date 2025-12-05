//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


/// An ``LLMSession`` that exposes its ``LLMSchema`` configuration.
///
/// This package-internal protocol allows access to the session's schema.
package protocol SchemaProvidingLLMSession: LLMSession {
    /// The ``LLMSchema`` type associated with this session.
    associatedtype Schema: LLMSchema

    /// The schema instance used to configure this session.
    var schema: Schema { get }
}
