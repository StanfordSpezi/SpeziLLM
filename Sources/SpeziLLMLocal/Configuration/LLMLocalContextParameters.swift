//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// Represents the context parameters of the LLM.
public struct LLMLocalContextParameters: Sendable {
    /// RNG seed of the LLM
    var seed: UInt64?
    
    /// If `true`, the mode is set to embeddings only
    var embeddingsOnly: Bool
    
    /// Creates the ``LLMLocalContextParameters`` which wrap the underlying llama.cpp `llama_context_params` C struct.
    /// Is passed to the underlying llama.cpp model in order to configure the context of the LLM.
    ///
    /// - Parameters:
    ///   - seed: RNG seed of the LLM, defaults to a random seed.
    ///   - embeddingsOnly: Embedding-only mode, defaults to `false`.
    public init(
        seed: UInt64? = nil,
        embeddingsOnly: Bool = false
    ) {
        self.seed = seed
        self.embeddingsOnly = embeddingsOnly
    }
}
