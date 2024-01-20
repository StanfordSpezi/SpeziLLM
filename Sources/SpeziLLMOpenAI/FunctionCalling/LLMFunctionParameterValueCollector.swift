//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziFoundation


/// Defines the `LLMFunctionParameterValueCollector/retrieve(_:)` requirement so that the ``LLMFunction/Parameter``s retrieve the function calling parameter values.
protocol LLMFunctionParameterValueCollector {
    /// Indicates if the ``LLMFunction/Parameter`` that retrieves the parameter value is optional.
    var isOptional: Bool { get }
    
    /// This method is called to retrieve the requested parameter value given the passed `Data`.
    ///
    /// - Parameter data: JSON-based parameter data.
    func retrieve(from data: Data) throws
}


extension _LLMFunctionParameterWrapper: LLMFunctionParameterValueCollector {
    var isOptional: Bool {
        // Only `Optional` conforms to `ExpressibleByNilLiteral`: https://developer.apple.com/documentation/swift/expressiblebynilliteral
        T.self is ExpressibleByNilLiteral.Type
        
        // TODO: Check if this works -> NO!
        // T.self is (any AnyOptional).Type
    }
    
    
    func retrieve(from data: Data) throws {
        self.inject(try JSONDecoder().decode(T.self, from: data))
    }
}

extension LLMFunction {
    /// All ``LLMFunction/Parameter``s conforming to `LLMFunctionParameterValueCollector`, mapped by their name.
    var parameterValueCollectors: [String: LLMFunctionParameterValueCollector] {
        retrieveProperties(ofType: LLMFunctionParameterValueCollector.self)
    }
    
    
    /// Retrieves all ``LLMFunction/Parameter``s (`@Parameter`s) including their name conforming to a certain `Value` from the ``LLMFunction``.
    ///
    /// - Parameters:
    ///    - type: Specifies which type of ``LLMFunction/Parameter``s should be retrieved.
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
    
    /// Injects the requested function call argument from the LLM into the ``LLMFunction``.
    ///
    /// - Parameters:
    ///    - parameterData: JSON-based parameter data of the ``LLMFunction``.
    func injectParameters(from parameterData: Data) throws {
        let topLayerParameterData = try JSONDecoder().decode(
            LLMFunctionParameterIntermediary.self,
            from: parameterData
        ).topLayerJSONRepresentation
        
        for (propertyName, propertyValue) in parameterValueCollectors {
            guard let propertyData = topLayerParameterData[propertyName] else {
                // If optional property, tolerable that there isn't a value
                if propertyValue.isOptional {
                    continue
                }
                
                let missingCodingKey = LLMFunctionParameterCodingKey(stringValue: propertyName)
                
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
