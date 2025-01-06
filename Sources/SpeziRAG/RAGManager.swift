//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import ObjectBox
import Foundation

public enum RAGManagerError: Error {
    case storeNotFound
}

public class RAGManager {
    
    private var store: Store
    private var box: Box<_RAGDocument>
    private let embedding: Embedding
    
    public init(
        storeName: String = "SpeziRAG",
        storeDirectory: URL? = nil,
        embedding: Embedding = DefaultEmbedding()
    ) throws {
        let directory = try storeDirectory ?? RAGManager.getStoreDirectory(name: storeName)
        let store = try Store(directoryPath: directory.path)
        self.store = store
        self.box = store.box(for: _RAGDocument.self)
        self.embedding = embedding
    }
    
    
    // MARK: Insert
    
    func insert(document: RAGDocument) throws {
        try box.put(document.toObjectBoxEntity())
    }
    
    public func insert(content: String, metadata: [String: String]) throws {
        let embedding = try embedding.embed(document: content)
        
        let doc = _RAGDocument.EntityType(
            content: content,
            metadata: metadata,
            embedding: embedding
        )
        
        try box.put(doc)
    }
    
    public func insert(items: [RAGDocument]) throws {
        var docs: [_RAGDocument] = []
        
        for item in items {
            let embedding = try embedding.embed(document: item.alternativeContent ?? item.content)
            
            docs.append(
                .EntityType(content: item.content, metadata: item.metadata, embedding: embedding)
            )
        }
        try box.put(docs)
    }
    
    
    // MARK: Get
    
    public func query(_ content: String, metadata: [String: String] = [:], maxCount: Int = 1) throws -> [RAGDocument] {
        let embedding = try embedding.embed(document: content)
  
        let query = try box.query {
            _RAGDocument.embedding.nearestNeighbors(queryVector: embedding, maxCount: maxCount)
        }.build()
        
        let results = try query.find(limit: maxCount)
        let filteredResults = results.filter { queryDict(metadata, in: $0.metadata) }
        
        return filteredResults.map(RAGDocument.fromObjectBoxEntity(_:))
    }
    
    public func getAll() throws -> [RAGDocument] {
        try box.all().map(RAGDocument.fromObjectBoxEntity)
    }
    
    
    // MARK: Delete
    
    public func delete(id: UInt64) throws {
        try box.remove(id)
    }
    
    public func deleteAll() throws {
        try box.removeAll()
    }
    
    
    // MARK: Private Functions
    
    private func queryDict(_ searchDict: [String: String], in dict: [String: String]) -> Bool {
        for (key, value) in searchDict {
            guard dict[key] == value else { return false }
        }
        return true
    }
    
    private static func getStoreDirectory(name: String) throws -> URL {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            throw RAGManagerError.storeNotFound
        }
        
        let appSupport = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent(bundleIdentifier)
        
        let directory = appSupport.appendingPathComponent(name)
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: nil
        )
        return directory
    }
}
