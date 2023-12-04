//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// An identifier for a ``LLMGenerationTask` based on the respective ``LLM``.
struct LLMTaskIdentifier: Hashable {
    /// The wrapped identifier of the `LLM``.
    let taskIdentifier: String
    
    
    /// Creates the `LLMTaskIdentifier` identifying ``LLM``'s.
    ///
    /// - Parameters:
    ///   - fromModel: The ``LLM`` that should be identified.
    init(fromModel model: any LLM) {
        self.taskIdentifier = String(describing: type(of: model))
    }
}
