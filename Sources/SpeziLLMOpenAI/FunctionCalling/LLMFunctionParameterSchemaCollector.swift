//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import OpenAPIRuntime
import OSLog


/// Defines the `LLMFunctionParameterSchemaCollector/schema` requirement to collect the function calling parameter schema's from the ``LLMFunction/Parameter``s.
///
/// Conformance of ``LLMFunction/Parameter`` to `LLMFunctionParameterSchemaCollector` can be found in the declaration of
/// the ``LLMFunction/Parameter``.
protocol LLMFunctionParameterSchemaCollector {
    var schema: LLMFunctionParameterItemSchema { get }
}

extension LLMFunction {
    typealias LLMFunctionParameterSchema = Components.Schemas.FunctionParameters
    var schemaValueCollectors: [String: LLMFunctionParameterSchemaCollector] {
        retrieveProperties(ofType: LLMFunctionParameterSchemaCollector.self)
    }
    
    /// Aggregates the individual parameter schemas of all ``LLMFunction/Parameter``s and combines them into the complete parameter schema of the ``LLMFunction``.
    var schema: LLMFunctionParameterSchema {
        let requiredPropertyNames = Array(
            parameterValueCollectors
                .filter {
                    !$0.value.isOptional
                }
                .keys
        )
        
        let properties = schemaValueCollectors.compactMapValues { $0.schema }
        
        var functionParameterSchema: LLMFunctionParameterSchema = .init()
        do {
            functionParameterSchema.additionalProperties = try .init(unvalidatedValue: [
                "type": "object",
                "properties": properties.mapValues { $0.value },
                "required": requiredPropertyNames
            ])
        } catch {
            Logger(subsystem: "edu.stanford.spezi", category: "SpeziLLMOpenAI").error("Error creating OpenAPIObjectContainer.")
        }
        return functionParameterSchema
    }
}
