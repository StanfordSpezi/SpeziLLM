//
//  Segment.swift
//  SpeziLLM
//
//  Created by Leon Nissen on 11/6/24.
//

import Foundation
import MLX

// Maybe change name of segment to document
// and change segment.document to content

// afterwards we could include more types of documents e.g. blob, health document, ...
// we could use a BaseMedia which holds the id and meta data

// add functions could afterwards accept multiple types of documents

public struct Segment {
    public let id: String
    public var document: String?
    public var metadata: [String: String]?
    public var embedding: MLXArray
    
    func toRaw() -> RawSegment {
        .init(id: id, document: document, metadata: metadata)
    }
}

struct RawSegment: Codable {
    public let id: String
    public let document: String?
    public let metadata: [String: String]?
}
