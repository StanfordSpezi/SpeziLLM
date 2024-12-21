//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import OpenAPIRuntime


// NOTE: OpenAPIRuntime.OpenAPIObjectContainer is the underlying type for Components.Schemas.FunctionParameters.additionalProperties

/// Alias of the OpenAI `JSONSchema/Property` type, describing properties within an object schema.
public typealias LLMFunctionParameterPropertySchema = OpenAPIRuntime.OpenAPIObjectContainer
/// Alias of the OpenAI `JSONSchema/Item` type, describing array items within an array schema.
public typealias LLMFunctionParameterItemSchema = OpenAPIRuntime.OpenAPIObjectContainer


/// Refer to the documentation of ``LLMFunction/Parameter`` for information on how to use the `@Parameter` property wrapper.
@propertyWrapper
public class _LLMFunctionParameterWrapper<T: Decodable>: LLMFunctionParameterSchemaCollector { // swiftlint:disable:this type_name
    private var injectedValue: T?
    
    
    var schema: LLMFunctionParameterItemSchema
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
    public convenience init(description _: some StringProtocol) where T: LLMFunctionParameter {
        self.init(schema: T.schema)
    }

    init(schema: LLMFunctionParameterItemSchema ) {
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
    public typealias Parameter<WrappedValue> =
        _LLMFunctionParameterWrapper<WrappedValue> where WrappedValue: Decodable
}
