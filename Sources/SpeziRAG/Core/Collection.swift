//
//  Collection.swift
//  SpeziLLM
//
//  Created by Leon Nissen on 11/5/24.
//

import Foundation

public struct CollectionMetadata: Codable {
    let id: String
    let name: String
//    let configuration: CollectionConfiguration
//    let embeddingFunction: EmbeddingFunction
    let createdAt: Date
    var updatedAt: Date
}

public enum IncludedDatum {
    case documents
    case embeddings
    case metadatas
    case distances
}


public struct GetResult {
    let ids: [String]
    let embeddings: [Float]?
    let documents: [String]?
    let metadata: [[String: String]]?
    let included: [IncludedDatum]
}

public indirect enum Filter {
    case date(Date)
    case dateRange(between: Date, and: Date)
    case title(search: String)
    case document(search: String)
    
    case or(Filter, Filter)
    case and(Filter, Filter)
}

public struct QueryResult {
    let ids: [String]
    let embeddings: [[Float]]?
    let documents: [String]?
    let distances: [Float]?
    let metadatas: [[String: String]]?
    let included: [IncludedDatum]
}
//
//public class Collection {
//    public typealias ID = String
//    public typealias Embedding = MLXArray
//    public typealias Metadata = [String: String]
//    public typealias Document = String
//    
//    private let storageURL: URL
//    private var metadata: CollectionMetadata
//    
//    private var segments: [Segment]
//    
//    @_disfavoredOverload
//    public init(metadata: CollectionMetadata, segments: [Segment] = [], storageURL: URL) {
//        self.metadata = metadata
//        self.segments = segments
//        self.storageURL = storageURL
//    }
//    
//    public init(from url: URL) throws {
//        guard FileManager.default.fileExists(atPath: url.path) else {
//            throw VectorDatabaseError.fileNotFound
//        }
//        
//        let (embeddings, additionalData) = try MLX.loadArraysAndMetadata(url: url)
//   
//        self.metadata = try additionalData.fromJSONString(key: "metadata", to: CollectionMetadata.self)
//        let rawSegments = try additionalData.fromJSONString(key: "segments", to: [RawSegment].self)
//        self.segments = []
//        
//        for rawSegment in rawSegments {
//            guard let embedding = embeddings[rawSegment.id] else {
//                continue
//            }
//            
//            self.segments.append(
//                .init(
//                    id: rawSegment.id,
//                    document: rawSegment.document,
//                    metadata: rawSegment.metadata,
//                    embedding: embedding
//                )
//            )
//        }
//        
//        self.storageURL = url
//    }
//    
//    public func count() -> Int {
//        segments.count
//    }
//    
//    public func add(id: ID? = nil, embedding: Embedding? = nil, metadata: Metadata? = nil, document: Document? = nil) throws {
//        guard embedding == nil && document != nil || embedding != nil && document == nil else {
//            throw VectorDatabaseError.invalidArgument
//        }
//        
//        let _embedding: Embedding? = if let embedding {
//            embedding
//        } else if let document {
//            try embed(document)
//        } else {
//            fatalError("Neither embedding nor document was provided.")
//        }
//        
//        let segment = Segment(
//            id: id ?? UUID().uuidString,
//            document: document,
//            metadata: metadata,
//            embedding: _embedding!
//        )
//        self.segments.append(segment)
//        
//        try save()
//    }
//    
//    public func get(
//        ids: [ID]? = nil,
//        limit: Int? = nil,
//        offset: Int? = nil,
//        filter: ((Segment) -> Bool)? = nil,
//        includes: [IncludedDatum] = [.documents, .metadatas]
//    ) throws -> GetResult {
//        var resultSet: [Segment] = []
//        
//        if let ids {
//            resultSet = self.segments.filter { ids.contains($0.id) }
//        } else {
//            resultSet = self.segments
//        }
//        
//        if let filter {
//            resultSet = resultSet.filter(filter)
//        }
//        
//        if let limit {
//            resultSet = Array(resultSet.prefix(limit))
//        }
//        
//        if let offset {
//            resultSet = Array(resultSet.suffix(resultSet.count - offset))
//        }
//        
//        var ids: [ID] = []
//        var documents: [Document] = []
//        var embeddings: [Embedding] = []
//        var metadatas: [Metadata] = []
//        
//        for index in resultSet.indices {
//            let segment = resultSet[index]
//            ids.append(segment.id)
//            
//            if includes.contains(.documents),
//               let document = segment.document {
//                documents.append(document)
//            }
//            
//            if includes.contains(.embeddings) {
//                embeddings.append(segment.embedding)
//            }
//            
//            if includes.contains(.metadatas),
//               let metadata = segment.metadata {
//                metadatas.append(metadata)
//            }
//        }
//        
//        return GetResult(
//            ids: ids,
//            embeddings: embeddings.isEmpty ? nil : embeddings,
//            documents: documents.isEmpty ? nil : documents,
//            metadata: metadatas.isEmpty ? nil : metadatas,
//            included: includes
//        )
//    }
//    
//    @available(*, unavailable)
//    public func peek(limit: Int = 10) throws -> GetResult { throw VectorDatabaseError.notImplemented }
//    
//    public func query(
//        queryEmbedding: Embedding? = nil,
//        queryText: String? = nil,
//        limit: Int = 10,
//        where filter: ((Segment) -> Bool)? = nil,
//        include: [IncludedDatum] = [.metadatas, .documents, .distances]
//    ) throws -> QueryResult {
//        guard queryEmbedding != nil || queryText != nil else {
//            throw VectorDatabaseError.invalidArgument
//        }
//        
//        var embedding: Embedding = []
//        
//        if let queryEmbedding {
//            embedding = queryEmbedding
//        } else if let queryText {
//            embedding = try embed(queryText)
//        }
//        
//        var resultSet = self.segments
//        
//        if let filter {
//            resultSet = resultSet.filter(filter)
//        }
//        
//        let embeddings: [MLXArray] = resultSet.map(\.embedding)
//        
//        // shape = [y, x]
//        let shape = [resultSet.count, self.metadata.configuration.dimension]
//        let mlxEmbeddings = MLX.stacked(embeddings).reshaped(shape)
//        
//        let scores = metadata.embeddingFunction.distances(between: embedding, and: mlxEmbeddings)
//        let topK = MLX.argSort(scores)[0 ..< limit]
//        
//        var resultIds: [ID] = []
//        var resultEmbeddings: [[Float]] = []
//        var resultDocuments: [String] = []
//        var resultDistances: [Float] = []
//        var resultMetadatas: [Metadata] = []
//        
//        for topKIndex in topK.asArray(Int.self) {
//            guard let segment = resultSet[safe: topKIndex] else {
//                continue
//            }
//            
//            resultIds.append(segment.id)
//            
//            if include.contains(.embeddings) {
//                resultEmbeddings.append(segment.embedding.asArray(Float.self))
//            }
//            
//            if include.contains(.distances) {
//                resultDistances.append(scores[topKIndex].item(Float.self))
//            }
//            
//            if include.contains(.documents),
//             let document = segment.document {
//                resultDocuments.append(document)
//            }
//            
//            if include.contains(.metadatas),
//               let metadata = segment.metadata {
//                resultMetadatas.append(metadata)
//            }
//        }
//        
//        return .init(
//            ids: resultIds,
//            embeddings: resultEmbeddings.isEmpty ? nil : resultEmbeddings,
//            documents: resultDocuments.isEmpty ? nil : resultDocuments,
//            distances: resultDistances.isEmpty ? nil : resultDistances,
//            metadatas: resultMetadatas.isEmpty ? nil : resultMetadatas,
//            included: include
//        )
//    }
//    
//    public func update(id: ID, embedding: Embedding? = nil, metadata: Metadata? = nil, document: Document? = nil) throws {
//        guard let oldIndex = self.segments.firstIndex(where: { $0.id == id }) else {
//            throw VectorDatabaseError.notFound
//        }
//        
//        if let embedding {
//            self.segments[oldIndex].embedding = embedding
//        }
//        
//        if let metadata {
//            self.segments[oldIndex].metadata = metadata
//        }
//        
//        if let document {
//            self.segments[oldIndex].document = document
//        }
//        
//        try save()
//    }
//    
//    public func upsert(id: ID, embedding: Embedding? = nil, metadata: Metadata? = nil, document: Document? = nil) throws {
//        if segments.contains(where: { $0.id == id }) {
//            try update(id: id, embedding: embedding, metadata: metadata, document: document)
//        } else {
//            try add(id: id, embedding: embedding, metadata: metadata, document: document)
//        }
//    }
//    
//    public func delete(id: ID, whereMetadata: [String: Any]? = nil, whereDocuments: [String: Any]? = nil) throws {
//        self.segments.removeAll(where: { $0.id == id })
//        try save()
//    }
//    
//    private func save() throws {
//        metadata.updatedAt = .now
//        
//        let additionalData = [
//            "segments": try segments.map({ $0.toRaw() }).toJSONString(),
//            "metadata": try metadata.toJSONString(),
//        ]
//        
//        let arrays = Dictionary(grouping: segments, by: { $0.id })
//            .compactMapValues(\.first)
//            .compactMapValues(\.embedding)
//        
//        try MLX.save(arrays: arrays, metadata: additionalData, url: self.storageURL)
//    }
//    
//    private func embed(_ string: String) throws -> MLXArray {
//        let embedder = NLEmbedding.sentenceEmbedding(for: metadata.configuration.language)
//        guard let embedder else {
//            throw VectorDatabaseError.languageNotSupported
//        }
//        
//        guard let vector = embedder.vector(for: string) else {
//            throw VectorDatabaseError.cannotVectorize
//        }
//        
//        return MLXArray(converting: vector)
//    }
//}
//
//
//public enum VectorDatabaseError: Error {
//    case unknown
//    case invalidData
//    case fileNotFound
//    case alredyExists
//    case notFound
//    case languageNotSupported
//    case cannotVectorize
//    case invalidArgument
//    case notImplemented
//}
//
//public extension Encodable {
//    func toJSONString() throws -> String {
//        guard let encodedData = try? JSONEncoder().encode(self),
//              let encodedString = String(data: encodedData, encoding: .utf8) else {
//            throw VectorDatabaseError.unknown
//        }
//        return encodedString
//    }
//}
//
//public extension Dictionary where Key == String, Value == String {
//    func fromJSONString<T: Codable>(key: String, to type: T.Type) throws -> T {
//        guard let string = self[key],
//              let data = string.data(using: .utf8),
//              let typedObject = try? JSONDecoder().decode(T.self, from: data) else {
//            throw VectorDatabaseError.invalidData
//        }
//        return typedObject
//    }
//}
//
//public extension Array {
//    subscript(safe index: Int) -> Element? {
//        return indices.contains(index) ? self[index] : nil
//    }
//}
