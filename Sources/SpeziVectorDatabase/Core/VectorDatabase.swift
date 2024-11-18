//
//  VectorDatabase.swift
//  SpeziLLM
//
//  Created by Leon Nissen on 11/5/24.
//

import Foundation
import MLX
import NaturalLanguage
import MLXLinalg
import MLXNN



public enum CollectionSpace: String, Codable {
    case l2
    case ip
    case cosine
}

public struct CollectionConfiguration: Codable {
    let space: CollectionSpace
    let batchSize: Int
    let dimension: Int
    let language: NLLanguage
    
    public init(space: CollectionSpace = .l2, batchSize: Int = 1000, dimension: Int = 512, language: NLLanguage = .english) {
        self.space = space
        self.batchSize = batchSize
        self.dimension = dimension
        self.language = language
    }
}


public class VectorDatabase {
    static private let vectorDatabaseDirectory = "spezi/vector_database"
    static private let fileExtension = "safetensors"
    
    private let baseURL: URL
    private let vectorDatabaseURL: URL
    private func collectionURL(name: String) -> URL {
        baseURL
            .appending(path: VectorDatabase.vectorDatabaseDirectory)
            .appendingPathComponent("collections")
            .appending(path: saveName(from: name))
            .appendingPathExtension(VectorDatabase.fileExtension)
    }
    
    private var collections: [String: URL]
    
    public init(url: URL = .documentsDirectory) throws {
        self.baseURL = url
        self.vectorDatabaseURL = baseURL
            .appending(path: VectorDatabase.vectorDatabaseDirectory)
            .appendingPathExtension(VectorDatabase.fileExtension)
        
        
        if FileManager.default.fileExists(atPath: vectorDatabaseURL.path()) {
            let (_, additionalData) = try MLX.loadArraysAndMetadata(url: vectorDatabaseURL)
            self.collections = try additionalData.fromJSONString(key: "collections", to: [String: URL].self)
        } else {
            let collectionsURL = baseURL
                .appending(path: VectorDatabase.vectorDatabaseDirectory)
                .appendingPathComponent("collections")
            try FileManager.default.createDirectory(at: collectionsURL, withIntermediateDirectories: true)
            self.collections = [:]
            try MLX.save(arrays: [:], metadata: [:], url: vectorDatabaseURL)
        }
    }
    
    public func countCollection() -> Int {
        collections.count
    }
    
    public func listCollections(offset: Int = 0, limit: Int? = nil) -> [String] {
        let keys = Array(collections.keys)
        
        if offset >= collections.count {
            return []
        }
        
        let offsetedKeys = Array(keys.suffix(keys.count - offset))
        
        if let limit {
            return Array(offsetedKeys.prefix(limit))
        }
        
        return offsetedKeys
    }
    
    public func getCollection(name: String) -> Collection? {
        guard let url = collections[name] else {
            return nil
        }
        
        if let collection = try? Collection(from: url) {
            return collection
        }
        return nil
    }
    
    @discardableResult
    public func createCollection(
        name: String,
        configuration: CollectionConfiguration = .init(),
        metadata: [String: String]? = nil,
        embeddingFunction: EmbeddingFunction = .cosine,
        getOrCreate: Bool = false
    ) throws -> Collection {
        if let url = collections[name] {
            if getOrCreate {
                return try Collection(from: url)
            } else {
                throw VectorDatabaseError.alredyExists
            }
        }
        
        let url = collectionURL(name: name)
        
        let metadata = CollectionMetadata(
            id: UUID().uuidString,
            name: name,
            configuration: configuration,
            embeddingFunction: embeddingFunction,
            createdAt: .now,
            updatedAt: .now
        )
        
        collections[metadata.name] = url
        try save()
        return Collection(metadata: metadata, storageURL: url)
    }
    
    public func deleteCollection(name: String) throws {
        guard let url = collections[name] else {
            throw VectorDatabaseError.notFound
        }
        
        try FileManager.default.removeItem(at: url)
        collections.removeValue(forKey: name)
        try save()
    }
    
    private func saveName(from name: String) -> String {
        String(name.lowercased().unicodeScalars.filter(CharacterSet.letters.contains))
    }
    
    private func save() throws {
        try MLX.save(
            arrays: [:],
            metadata: ["collections": try collections.toJSONString()],
            url: vectorDatabaseURL
        )
    }
}


extension NLLanguage: Codable {
    
}
