//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


protocol ParameterValueCollector {
    var isOptional: Bool { get }
    
    /// This method is called to retrieve all the requested values from the given ``SpeziStorage`` repository.
    /// - Parameter repository: Provides access to the ``SpeziStorage`` repository for read access.
    func retrieve(from data: Data) throws
}

extension _LLMFunctionParameterWrapper: ParameterValueCollector {
    var isOptional: Bool {
        // Only `Optional` conforms to `ExpressibleByNilLiteral`: https://developer.apple.com/documentation/swift/expressiblebynilliteral
        T.self is ExpressibleByNilLiteral.Type
    }
    
    
    public func retrieve(from data: Data) throws {
        self.inject(try JSONDecoder().decode(T.self, from: data))
    }
}

extension LLMFunction {
    var storageValueCollectors: [String: ParameterValueCollector] {
        retrieveProperties(ofType: ParameterValueCollector.self)
    }
    
    
    func retrieveProperties<Value>(ofType type: Value.Type) -> [String: Value] {
        let mirror = Mirror(reflecting: self)

        return mirror.children.reduce(into: [String: Value]()) { partialResult, child in
            guard let label = child.label?.dropFirst(), // Necessary to remove "_" from property wrapper value
                  let value = child.value as? Value else {
                return
            }

            partialResult[String(label)] = value
        }
    }
    
    func injectParameters(from parameterData: Data) throws {
        let topLayerParameterData = try JSONDecoder().decode(LLMFunctionParameterJSON.self, from: parameterData).topLayerJSONRepresentation
        
        for (propertyName, propertyValue) in storageValueCollectors {
            guard let propertyData = topLayerParameterData[propertyName] else {
                // If optional property, tolerable that there isn't a value
                if propertyValue.isOptional {
                    continue
                }
                
                let missingCodingKey = LLMCodingKey(stringValue: propertyName)
                
                throw DecodingError.keyNotFound(
                    missingCodingKey,
                    .init(
                        codingPath: [missingCodingKey],
                        debugDescription: "Mismatch between the defined values of the LLM Function and the requested values by the LLM"
                    )
                )
            }
            
            try propertyValue.retrieve(from: propertyData)
        }
    }
}
