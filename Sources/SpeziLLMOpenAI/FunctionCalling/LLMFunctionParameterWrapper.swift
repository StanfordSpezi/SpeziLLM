//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import OpenAI


/// Alias of the OpenAI `JSONSchema/Property` type
public typealias LLMFunctionParameterPropertySchema = JSONSchema.Property


/// Refer to the documentation of ``LLMFunction/Parameter`` for information on how to use the `@Parameter` property wrapper.
@propertyWrapper
public class _LLMFunctionParameterWrapper<T: LLMFunctionParameter>: LLMFunctionParameterSchemaCollector { // swiftlint:disable:this type_name
    private var injectedValue: T?
    var schema: LLMFunctionParameterPropertySchema
    
    
    public var wrappedValue: T {
        guard let value = injectedValue else {
            preconditionFailure("""
                                Tried to access @Parameter for value [\(T.self)] which wasn't injected yet. \
                                Are you sure that you declared the function call within the respective SpeziLLM functions and
                                only access the @Parameter within the `LLMFunction/execute()` method?
                                """)
        }
        
        return value
        
        /*
        // Only `Optional` conforms to `ExpressibleByNilLiteral`: https://developer.apple.com/documentation/swift/expressiblebynilliteral
        if T.self is ExpressibleByNilLiteral.Type {
            // If T is Optional, return the optional value (which could be nil).
            return injectedValue as! T  // swiftlint:disable:this force_cast
        } else {
            // If T is non-Optional, fail if the value isn't injected yet.
            guard let value = injectedValue else {
                preconditionFailure("""
                                    Tried to access @Parameter for value [\(T.self)] which wasn't injected yet. \
                                    Are you sure that you declared the function call within the respective SpeziLLM functions and
                                    only access the @Parameter within the `LLMFunction/execute()` method?
                                    """)
            }
            return value
        }
         */
    }
    
    
    /// Creates an ``LLMFunction/Parameter`` which contains a custom-defined type that conforms to ``LLMFunctionParameter``.
    /// The custom-defined type needs to implement the ``LLMFunctionParameter`` protocol which mandates the implementation of the
    /// ``LLMFunctionParameter/schema`` property, describing the JSON schema of the property necessary for OpenAI.
    ///
    /// - Parameters:
    ///    - description: Describes the purpose of the parameter, used by the LLM to grasp the purpose of the parameter.
    public init(description: String) {
        self.schema = .init(
            type: T.schema.type,
            description: description,   // Take description from the property wrapper, all other things from self defined schema
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
        )
    }
    
    
    func inject(_ value: T) {
        self.injectedValue = value
    }
}


extension LLMFunction {
    /// Defines parameters within an ``LLMFunction``.
    ///
    /// The `@Parameter` property wrapper can be used within an ``LLMFunction`` to declare that the function takes a single argument.
    /// As the function is called by the LLM, the parameters that are requested are automatically filled by SpeziLLM.
    /// The wrapper contains lots of different initializers for the respective wrapped types of the parameter, such as `Int`, `Float`, `Double`, `Bool` or `String`, as well as optional, `array`, and `enum` data types.
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
    public typealias Parameter<Value> = _LLMFunctionParameterWrapper<Value> where Value: LLMFunctionParameter
}
