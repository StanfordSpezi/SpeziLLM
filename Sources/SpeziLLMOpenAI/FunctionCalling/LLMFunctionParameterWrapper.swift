//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable file_types_order

import Foundation
import OpenAPIRuntime


// NOTE: OpenAPIRuntime.OpenAPIObjectContainer is the underlying type for Components.Schemas.FunctionParameters.additionalProperties

/// Alias of the OpenAI `JSONSchema/Property` type, describing properties within an object schema.
public typealias LLMFunctionParameterPropertySchema = OpenAPIRuntime.OpenAPIObjectContainer
/// Alias of the OpenAI `JSONSchema/Item` type, describing array items within an array schema.
public typealias LLMFunctionParameterItemSchema = OpenAPIRuntime.OpenAPIObjectContainer


/// Stores the decoded `@Parameter` values for ``LLMFunction``s currently being executed.
///
/// This type exists because ``_LLMFunctionParameterWrapper`` is a reference type, meaning that if the same LLMFunction is
/// executed multiple times in parallel, each instance of the function (which is a struct) could end up pointing to the same parameter storage,
/// and multiple executions would operate on the same inputs (or the input could change mid-execution).
///
/// So what we do instead is that we have a Task-local dictionary of the decoded values (ie, the function parameters),
/// and use the `@Parameter` as a key into that dictionary.
///
/// (We need to put this in here bc the `_LLMFunctionParameterWrapper` itself cannot contain static stored properties.
private enum LLMFunctionParameterStorage {
    @TaskLocal static var currentValues: [ObjectIdentifier: any Sendable] = [:]
}


internal protocol LLMFunctionParameterWrapperProtocol: AnyObject, Sendable {
    /// The underlying type of the parameter
    associatedtype Value: Decodable, Sendable
    
    /// Indicates if the ``LLMFunction/Parameter`` that retrieves the parameter value is optional.
    var isOptional: Bool { get }
    
    /// JSON-decodes a parameter value
    func decode(from data: Data) throws -> Value
}


extension LLMFunctionParameterWrapperProtocol {
    /// The key used when storing a value for this parameter into the ``LLMFunctionParameterStorage``
    var storageKey: ObjectIdentifier {
        ObjectIdentifier(self)
    }
}


/// Refer to the documentation of ``LLMFunction/Parameter`` for information on how to use the `@Parameter` property wrapper.
@propertyWrapper
public final class _LLMFunctionParameterWrapper<Value: Decodable & Sendable>: LLMFunctionParameterSchemaCollector {
    // swiftlint:disable:previous type_name
    let schema: LLMFunctionParameterItemSchema
    
    public var wrappedValue: Value {
        if let value = LLMFunctionParameterStorage.currentValues[ObjectIdentifier(self)] as? Value {
            // If the unwrapped injectedValue is not nil, return the non-nil value
            return value
        } else if let selfCasted = self as? any NilValueProtocol {
            // If the unwrapped injectedValue is nil, return nil
            return selfCasted.nilValue(Value.self)  // Need an indirection to enable to return nil as type T
        } else {
            // Fail if not injected yet
            fatalError("""
                Tried to access @Parameter for value [\(Value.self)] which wasn't injected yet. \
                Are you sure that you declared the function call within the respective SpeziLLM functions and \
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
    public convenience init(description _: some StringProtocol) where Value: LLMFunctionParameter {
        self.init(schema: Value.schema)
    }

    init(schema: LLMFunctionParameterItemSchema) {
        self.schema = schema
    }
}


extension _LLMFunctionParameterWrapper: LLMFunctionParameterWrapperProtocol {
    typealias Value = Value
    
    var isOptional: Bool {
        // Only `Optional` conforms to `ExpressibleByNilLiteral`: https://developer.apple.com/documentation/swift/expressiblebynilliteral
        Value.self is any ExpressibleByNilLiteral.Type
    }
    
    func decode(from data: Data) throws -> Value {
        try JSONDecoder().decode(Value.self, from: data)
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
    
    
    /// Executes the function, with the specified parameter-value mappign injected for the duration of the execution.
    internal func _execute(_ arguments: consuming LLMFunctionCallArguments) async throws -> String? { // swiftlint:disable:this identifier_name
        try await LLMFunctionParameterStorage.$currentValues.withValue(arguments.values) {
            try await self.execute()
        }
    }
}
