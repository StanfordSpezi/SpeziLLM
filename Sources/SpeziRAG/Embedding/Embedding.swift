//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation

public enum EmbeddingError: Error {
    case invalidInput
    case cannotEmbed
    case custom(String)
}


public protocol Embedding {
    var dimension: Int { get }
    
    func embed(document: String) throws -> [Float]
    
    func embed(query: String) throws -> [Float]
}
