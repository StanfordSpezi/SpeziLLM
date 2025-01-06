//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import ObjectBox
import Foundation


public struct RAGDocument {
    let id: UInt64?
    let content: String
    let alternativeContent: String?
    let metadata: [String: String]
    let embedding: [Float]?
    let similarity: Float?
    
    public init(
        id: UInt64?,
        content: String,
        alternativeContent: String?,
        metadata: [String : String],
        embedding: [Float]?,
        similarity: Float?
    ) {
        self.id = id
        self.content = content
        self.alternativeContent = alternativeContent
        self.metadata = metadata
        self.embedding = embedding
        self.similarity = similarity
    }
    
    internal func toObjectBoxEntity() -> _RAGDocument {
        .init(id: id ?? 0, content: content, metadata: metadata, embedding: embedding ?? [])
    }
    
    static internal func fromObjectBoxEntity(_ entity: _RAGDocument) -> RAGDocument {
        .init(
            id: entity.id,
            content: entity.content,
            alternativeContent: entity.alternativeContent,
            metadata: entity.metadata,
            embedding: entity.embedding,
            similarity: nil
        )
    }
}



// objectbox: entity
class _RAGDocument {
    var id: Id = 0
    var content: String = ""
    var alternativeContent: String = ""
    var _metadata: Data = .init()
    // objectbox:hnswIndex: dimensions=512
    var embedding: [Float] = []
    
    init() { }
    
    init(id: Id = 0, content: String = "", alernativeContent: String = "", metadata: [String: String] = [:], embedding: [Float] = []) {
        self.id = id
        self.content = content
        self.alternativeContent = alernativeContent
        self.metadata = metadata
        self.embedding = embedding
    }
    
    var metadata: [String: String] {
        get {
            (try? JSONDecoder().decode([String: String].self, from: _metadata)) ?? [:]
        }
        set {
            _metadata = (try? JSONEncoder().encode(newValue)) ?? .init()
        }
    }
}
