//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


package struct LLMFunctionCallArguments: Sendable, ~Copyable {
    let values: [ObjectIdentifier: any Sendable]
    
    /// Creates a new Function Call Arguments object, by decoding them from JSON.
    init(from encodedArguments: Data, for function: some LLMFunction) throws {
        let topLayerParameterData = try JSONDecoder().decode(
            LLMFunctionParameterIntermediary.self,
            from: encodedArguments
        ).topLayerJSONRepresentation
        values = try function.parameters.reduce(into: [:]) { result, parameter in
            let (paramName, parameter) = parameter
            if let data = topLayerParameterData[paramName] {
                result[parameter.storageKey] = try parameter.decode(from: data)
            } else {
                guard !parameter.isOptional else {
                    // If optional property, tolerable that there isn't a value
                    return
                }
                let missingCodingKey = LLMFunctionParameterCodingKey(stringValue: paramName)
                throw DecodingError.keyNotFound(
                    missingCodingKey,
                    .init(
                        codingPath: [missingCodingKey],
                        debugDescription: "Mismatch between the defined values of the LLM Function and the requested values by the LLM"
                    )
                )
            }
        }
    }
}


extension LLMFunction {
    /// All ``LLMFunction/Parameter``s, mapped by their name.
    var parameters: [String: any LLMFunctionParameterWrapperProtocol] {
        retrieveProperties(ofType: (any LLMFunctionParameterWrapperProtocol).self)
    }


    /// Retrieves all ``LLMFunction/Parameter``s (`@Parameter`s) including their name conforming to a certain `Value` from the ``LLMFunction``.
    ///
    /// - Parameters:
    ///    - type: Specifies which type of ``LLMFunction/Parameter``s should be retrieved.
    func retrieveProperties<Value>(ofType type: Value.Type) -> [String: Value] {
        let mirror = Mirror(reflecting: self)
        return mirror.children.reduce(into: [:]) { result, child in
            guard let label = child.label?.dropFirst(), // Necessary to remove "_" from property wrapper value
                  let value = child.value as? Value else {
                return
            }
            result[String(label)] = value
        }
    }

    
//    /// Decodes the function-call arguments JSON into a per-call `[ObjectIdentifier: any Sendable]` dictionary.
//    ///
//    /// - Note: See ``LLMFunctionParameterStorage`` for more info.
//    ///
//    /// - parameter parameterData: JSON-based parameter data of the ``LLMFunction``.
//    /// - returns: A dicttionary mapping the function's `@Parameter`s to their respective values for a function call with these arguments.
//    func decodeParameterValues(from parameterData: Data) throws -> LLMFunctionArguments {
//        let topLayerParameterData = try JSONDecoder().decode(
//            LLMFunctionParameterIntermediary.self,
//            from: parameterData
//        ).topLayerJSONRepresentation
//        return LLMFunctionArguments(_values: try parameters.reduce(into: [:]) { result, parameter in
//            let (paramName, parameter) = parameter
//            if let data = topLayerParameterData[paramName] {
//                result[parameter.storageKey] = try parameter.decode(from: data)
//            } else {
//                guard !parameter.isOptional else {
//                    // If optional property, tolerable that there isn't a value
//                    return
//                }
//                let missingCodingKey = LLMFunctionParameterCodingKey(stringValue: paramName)
//                throw DecodingError.keyNotFound(
//                    missingCodingKey,
//                    .init(
//                        codingPath: [missingCodingKey],
//                        debugDescription: "Mismatch between the defined values of the LLM Function and the requested values by the LLM"
//                    )
//                )
//            }
//        })
//    }
}
