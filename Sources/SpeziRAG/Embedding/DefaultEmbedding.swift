//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import NaturalLanguage
import Foundation

public class DefaultEmbedding: Embedding {
    
    public init() { }
    
    public var dimension: Int {
        512
    }
    
    public func embed(document: String) throws -> [Float] {
        try embed(document)
    }
    
    public func embed(query: String) throws -> [Float] {
        try embed(query)
    }
    
    private func embed(_ input: String) throws -> [Float] {
        guard let embedder = NLEmbedding.sentenceEmbedding(for: .english) else {
            throw EmbeddingError.custom("Cannot load embedder")
        }
        
        guard let embedding = embedder.vector(for: input) else {
            throw EmbeddingError.cannotEmbed
        }
        return embedding.map(Float.init)
    }
}
