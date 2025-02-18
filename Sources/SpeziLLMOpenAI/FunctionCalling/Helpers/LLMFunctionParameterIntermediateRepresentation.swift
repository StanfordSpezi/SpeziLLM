//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// Serves as an intermediary representation of the requested function call parameters in order to decode the parameters into the ``LLMFunction/Parameter``s.
enum LLMFunctionParameterIntermediary: Codable {
    case null
    case int(Int)
    case bool(Bool)
    case string(String)
    case double(Double)
    case array(Array<LLMFunctionParameterIntermediary>)
    case dictionary([String: LLMFunctionParameterIntermediary])


    static let encoder = JSONEncoder()

    
    /// Provides a representation of the received JSON where each first-level parameter (the key) maps to the respective nested JSON `Data`.
    var topLayerJSONRepresentation: [String: Data] {
        get throws {
            guard case let .dictionary(dictionary) = self else {
                return [:]
            }
            
            return try dictionary.mapValues {
                try Self.encoder.encode($0)
            }
        }
    }
    
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([LLMFunctionParameterIntermediary].self) {
            self = .array(array)
        } else if let dictionary = try? container.decode([String: LLMFunctionParameterIntermediary].self) {
            self = .dictionary(dictionary)
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Encountered unexpected JSON values within LLM Function Calling Parameters"
                )
            )
        }
    }
    
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .null:
            return
        case let .int(int):
            try container.encode(int)
        case let .bool(bool):
            try container.encode(bool)
        case let .string(string):
            try container.encode(string)
        case let .double(double):
            try container.encode(double)
        case let .array(array):
            try container.encode(array)
        case let .dictionary(dictionary):
            try container.encode(dictionary)
        }
    }
}
