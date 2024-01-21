//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import OpenAI


/// Alias of the OpenAI `JSONSchema/Property` type, describing properties within an object schema.
public typealias LLMFunctionParameterPropertySchema = JSONSchema.Property
/// Alias of the OpenAI `JSONSchema/Item` type, describing array items within an array schema.
public typealias LLMFunctionParameterItemSchema = JSONSchema.Items


/// Refer to the documentation of ``LLMFunction/Parameter`` for information on how to use the `@Parameter` property wrapper.
@propertyWrapper
public class _LLMFunctionParameterWrapper<T: Decodable, D: StringProtocol>: LLMFunctionParameterSchemaCollector { // swiftlint:disable:this type_name
    private var injectedValue: T?
    var schema: LLMFunctionParameterPropertySchema
    
    
    public var wrappedValue: T {
        // If the unwrapped injectedValue is not nil, return the non-nil value
        if let value = injectedValue {
            return value
        // If the unwrapped injectedValue is nil, return nil
        } else if let selfCasted = self as? NilValueProtocol {
            return selfCasted.nilValue(T.self)  // Need an indirection to enable to return nil as type T
        // Fail if not injected yet
        } else {
            preconditionFailure("""
                                Tried to access @Parameter for value [\(T.self)] which wasn't injected yet. \
                                Are you sure that you declared the function call within the respective SpeziLLM functions and
                                only access the @Parameter within the `LLMFunction/execute()` method?
                                """)
        }
    }
    
    
    /// Creates an ``LLMFunction/Parameter`` which contains a custom-defined type that conforms to ``LLMFunctionParameter``.
    ///
    /// The custom-defined type needs to implement the ``LLMFunctionParameter`` protocol which mandates the implementation of the
    /// ``LLMFunctionParameter/schema`` property, describing the JSON schema of the property necessary for OpenAI.
    ///
    /// More documentation about parameters that are supported by OpenAI can be found here: https://json-schema.org/draft-07/json-schema-validation
    ///
    /// - Parameters:
    ///    - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    @_disfavoredOverload
    public convenience init(description: D) where T: LLMFunctionParameter {
        self.init(schema: .init(
            type: T.schema.type,
            description: String(description),   // Take description from the property wrapper, all other things from self defined schema
            format: T.schema.format,
            items: T.schema.items,
            required: T.schema.required,
            pattern: T.schema.pattern,
            const: T.schema.const,
            enumValues: T.schema.enumValues,
            multipleOf: T.schema.multipleOf,
            minimum: T.schema.minimum,
            maximum: T.schema.maximum,
            minItems: T.schema.minItems,
            maxItems: T.schema.maxItems,
            uniqueItems: T.schema.uniqueItems
        ))
    }
    
    init(schema: LLMFunctionParameterPropertySchema) {
        self.schema = schema
    }
    
    
    func inject(_ value: T) where T: Decodable {
        self.injectedValue = value
    }
}


extension LLMFunction {
    /// Defines parameters within an ``LLMFunction``.
    ///
    /// The `@Parameter` property wrapper (``LLMFunction/Parameter``) can be used within an ``LLMFunction`` to declare that the function takes a number of arguments of specific type.
    /// As the function is called by the LLM, the function parameters that are sent by the LLM are automatically injected into the ``LLMFunction`` by ``SpeziLLMOpenAI``.
    ///
    /// The wrapper contains various initializers for the respective wrapped types of the parameter, such as `Int`, `Float`, `Double`, `Bool` or `String`, as well as `Optional`, `array`, and `enum` data types.
    /// For these types, ``SpeziLLMOpenAI`` is able to automatically synthezise the OpenAI function parameter schema from the declared ``LLMFunction/Parameter``s.
    ///
    /// > Tip: In case developers want to manually define schema's for custom and complex types, please refer to ``LLMFunctionParameter``, ``LLMFunctionParameterEnum``, and ``LLMFunctionParameterArrayElement``.
    ///
    /// # Usage
    ///
    /// The example below demonstrates a simple use case of an ``LLMFunction/Parameter`` within a ``LLMFunction``.
    ///
    /// ```swift
    /// struct WeatherFunction: LLMFunction {
    ///     @Parameter(description: "The city and state of the to be determined weather, e.g. San Francisco, CA")
    ///     var location: String
    ///
    ///     func execute() async throws -> String {
    ///         "The weather at \(location) is 30 degrees"
    ///     }
    /// }
    /// ```
    public typealias Parameter<WrappedValue, Description> =
        _LLMFunctionParameterWrapper<WrappedValue, Description> where WrappedValue: Decodable, Description: StringProtocol
}
