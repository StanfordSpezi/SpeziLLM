//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// Defines the `LLMFunctionParameterValueCollector/decodeValue(from:)` requirement so that the ``LLMFunction/Parameter``s decode the function calling parameter values.
protocol LLMFunctionParameterValueCollector: AnyObject {
    /// Indicates if the ``LLMFunction/Parameter`` that retrieves the parameter value is optional.
    var isOptional: Bool { get }
    
    /// Decodes the requested parameter value given the passed `Data`.
    ///
    /// The value isn't stored in the ``LLMFunction/Parameter``, as the ``LLMFunction`` is shared by all of its invocations.
    ///
    /// - Parameter data: JSON-based parameter data.
    /// - Returns: The decoded parameter value.
    func decodeValue(from data: Data) throws -> any Sendable
}


extension _LLMFunctionParameterWrapper: LLMFunctionParameterValueCollector {
    var isOptional: Bool {
        // Only `Optional` conforms to `ExpressibleByNilLiteral`: https://developer.apple.com/documentation/swift/expressiblebynilliteral
        T.self is any ExpressibleByNilLiteral.Type
    }
    
    
    func decodeValue(from data: Data) throws -> any Sendable {
        try JSONDecoder().decode(T.self, from: data)
    }
}

extension LLMFunction {
    /// All ``LLMFunction/Parameter``s conforming to `LLMFunctionParameterValueCollector`, mapped by their name.
    var parameterValueCollectors: [String: any LLMFunctionParameterValueCollector] {
        retrieveProperties(ofType: (any LLMFunctionParameterValueCollector).self)
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
    
    /// Decodes the requested function call arguments from the LLM for a single invocation of the ``LLMFunction``.
    ///
    /// The returned arguments are passed to ``LLMFunction/execute(with:)``; they aren't stored in the shared ``LLMFunction`` instance.
    /// Optional parameters that are missing in `parameterData` are `nil` for this invocation.
    ///
    /// - Parameters:
    ///    - parameterData: JSON-based parameter data of the ``LLMFunction``.
    /// - Returns: The decoded arguments of the invocation.
    package func decodeArguments(from parameterData: Data) throws -> LLMFunctionArguments {
        let topLayerParameterData = try JSONDecoder().decode(
            LLMFunctionParameterIntermediary.self,
            from: parameterData
        ).topLayerJSONRepresentation
        
        var values: [ObjectIdentifier: any Sendable] = [:]
        
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
            
            values[ObjectIdentifier(propertyValue)] = try propertyValue.decodeValue(from: propertyData)
        }
        
        return LLMFunctionArguments(values: values)
    }
}
