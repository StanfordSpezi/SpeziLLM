//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SwiftUI


/// Defines a collection of ``SpeziLLMOpenAI`` ``LLMFunction``s.
///
/// You can not create a `_LLMFunctionCollection` yourself. Please use the ``LLMOpenAISchema`` that internally creates a `_LLMFunctionCollection` with the passed ``LLMFunction``s.
public struct _LLMFunctionCollection {  // swiftlint:disable:this type_name
    package let functions: [String: any LLMFunction]
    
    package init(functions: [any LLMFunction]) {
        self.functions = functions.reduce(into: [:]) {
            $0[type(of: $1).name] = $1
        }
    }
    
    /// Creates an empty `_LLMFunctionsCollection`
    public init() {
        functions = [:]
    }
}
