//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


// Model schema, including the generation and all config possibilities
// A LLM is always bound to a LLMPlatform
public protocol LLMSchema {
    associatedtype Platform: LLMPlatform
    /// Indicates if the inference output by the ``LLMSession`` should automatically be inserted into the ``LLMSession/context``.
    var injectIntoContext: Bool { get }
}
