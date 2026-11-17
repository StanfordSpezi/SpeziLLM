//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import OpenAPIRuntime
import OSLog


// NOTE: OpenAPIRuntime.OpenAPIObjectContainer is the underlying type for Components.Schemas.FunctionParameters.additionalProperties

/// Alias of the OpenAI `JSONSchema/Property` type, describing properties within an object schema.
public typealias LLMFunctionParameterPropertySchema = OpenAPIRuntime.OpenAPIObjectContainer
/// Alias of the OpenAI `JSONSchema/Item` type, describing array items within an array schema.
public typealias LLMFunctionParameterItemSchema = OpenAPIRuntime.OpenAPIObjectContainer


/// Refer to the documentation of ``LLMFunction/Parameter`` for information on how to use the `@Parameter` property wrapper.
@propertyWrapper
public final class _LLMFunctionParameterWrapper<T: Decodable & Sendable>: LLMFunctionParameterSchemaCollector { // swiftlint:disable:this type_name
    /// A Swift Logger that logs important information and errors.
    let logger = Logger(subsystem: "edu.stanford.spezi", category: "SpeziLLMOpenAI")

    let schema: LLMFunctionParameterItemSchema

    /// The argument of the ``LLMFunction`` invocation that is executed by the current task.
    ///
    /// The ``LLMFunction`` (and with it this property wrapper) is shared by all invocations of the function, so the value is not
    /// stored here but read from the arguments bound to the task that executes ``LLMFunction/execute()``.
    /// Accessing the value outside of the task executing ``LLMFunction/execute()`` (or one of its child tasks or unstructured `Task`s
    /// created from it) is a programming error.
    public var wrappedValue: T {
        guard let arguments = LLMFunctionArguments.current else {
            fatalError("""
            Tried to access @Parameter for value [\(T.self)] outside of an LLM function invocation. \
            @Parameters can only be accessed from within the `LLMFunction/execute()` method, including child tasks and \
            `Task`s created there, but not from `Task.detached` or from code that runs after `execute()` returned.
            """)
        }

        // The argument was sent by the LLM
        if let value = arguments.value(for: ObjectIdentifier(self)) {
            guard let value = value as? T else {
                fatalError("Inconsistent code: Stored argument of type [\(type(of: value))] doesn't match @Parameter type [\(T.self)].")
            }
            return value
        // The LLM omitted the argument, only valid for optional parameters
        } else if let selfCasted = self as? any NilValueProtocol {
            return selfCasted.nilValue(T.self)  // Need an indirection to enable to return nil as type T
        } else {
            fatalError("""
            Tried to access @Parameter for value [\(T.self)] which wasn't passed for the current LLM function invocation. \
            Are you sure that you declared the function call within the respective SpeziLLM functions?
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

    init(schema: LLMFunctionParameterItemSchema) {
        self.schema = schema
    }
}


extension LLMFunction {
    /// Defines parameters within an ``LLMFunction``.
    ///
    /// The `@Parameter` property wrapper (``LLMFunction/Parameter``) can be used within an ``LLMFunction`` to declare that the function takes a number of arguments of specific type.
    /// As the function is called by the LLM, the function parameters that are sent by the LLM are automatically injected into the ``LLMFunction`` by ``SpeziLLMOpenAI``.
    ///
    /// Every invocation of the ``LLMFunction`` observes exactly the arguments the LLM sent for that invocation, even if the LLM requests
    /// the same function multiple times and the invocations are executed in parallel. Optional parameters that the LLM omitted are `nil`.
    ///
    /// > Important: The arguments are bound to the task executing ``LLMFunction/execute()``. Access `@Parameter`s only from within
    /// ``LLMFunction/execute()``, including its child tasks and `Task`s created within it. Accessing them from a `Task.detached`,
    /// from callbacks that are invoked outside of Swift concurrency (e.g., on a `DispatchQueue`), or after ``LLMFunction/execute()``
    /// returned results in a runtime error. If you need the values in such a context, copy them into local constants first.
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
