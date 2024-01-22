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
/// You can not create a `_LLMFunctionCollection` yourself. Please use the ``LLMOpenAI`` that internally creates a `_LLMFunctionCollection` with the passed ``LLMFunction``s.
public struct _LLMFunctionCollection {  // swiftlint:disable:this type_name
    var functions: [String: LLMFunction] = [:]
    
    
    init(functions: [any LLMFunction]) {
        for function in functions {
            self.functions[Swift.type(of: function).name] = function
        }
    }
}
