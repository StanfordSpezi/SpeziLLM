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
    let seed: UInt64?
    
    /// Creates the ``LLMLocalContextParameters`` which wrap the underlying llama.cpp `llama_context_params` C struct.
    /// Is passed to the underlying llama.cpp model in order to configure the context of the LLM.
    ///
    /// - Parameters:
    ///   - seed: RNG seed of the LLM, defaults to a random seed.
    public init(
        seed: UInt64? = nil
    ) {
        self.seed = seed
    }
}
