//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import OpenAI


protocol LLMFunctionParameterSchemaCollector: Decodable {
    var schema: LLMFunctionParameterPropertySchema { get }
}


extension LLMFunction {
    typealias LLMFunctionParameterSchema = JSONSchema
    
    
    var schemaValueCollectors: [String: LLMFunctionParameterSchemaCollector] {
        retrieveProperties(ofType: LLMFunctionParameterSchemaCollector.self)
    }
    
    var schema: LLMFunctionParameterSchema {
        let requiredPropertyNames = Array(
            storageValueCollectors
                .filter {
                    !$0.value.isOptional
                }
                .keys
        )
        
        let properties = schemaValueCollectors.compactMapValues { $0.schema }
        
        return .init(
            type: .object,
            properties: properties,
            required: requiredPropertyNames
        )
    }
}
