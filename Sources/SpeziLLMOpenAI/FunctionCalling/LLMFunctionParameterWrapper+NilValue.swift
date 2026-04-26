//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziFoundation


protocol NilValueProtocol {
    func nilValue<V>(_ value: V.Type) -> V
}

/// If injected type T of ``LLMFunction/Parameter`` is an `Optional`, enable the conformance of `nil` to static type T
extension _LLMFunctionParameterWrapper: NilValueProtocol where Value: AnyOptional {
    func nilValue<V>(_ value: V.Type) -> V {
        guard let nilLiteral = Value(nilLiteral: ()) as? V else {
            fatalError(
            """
            Inconsistent code: Could not cast T to passed Value (which has to be T)
            """
            )
        }
        
        return nilLiteral
    }
}
