//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import OpenAI


/// Represents LLM function calling parameters.
///
/// Every parameter used within an ``LLMFunction`` via the ``LLMFunction/Parameter`` (`@Parameter`) needs to conform to the ``LLMFunctionParameter`` protocol.
/// The protocol enforces the ``LLMFunctionParameter/schema`` property, which every ``LLMFunction/Parameter`` needs to implement so that OpenAI LLMs are able to
/// structure the function call parameters.
///
/// For primitive types, arrays of primitive types as well as optionals of primitive types, the conformance to the ``LLMFunctionParameter`` protocol is done by SpeziLLM.
/// For `enum`s, please refer to the ``LLMFunctionParameterEnum``.
/// 
/// > Tip: For custom and more complex types, one needs to manually implement the conformance to the protocol as SpeziLLM is not able to automatically synthesise the schema.
///
/// # Usage
///
/// An example usage of the ``LLMFunctionParameter`` for a custom type looks like the following:
///
/// ```swift
/// struct WeatherFunction: LLMFunction {
///     struct CustomType: LLMFunctionParameter {
///         // Manually implement the conformance to the `LLMFunctionParameter` protocol, enforcing the declaration of the parameter schema.
///         static var schema: LLMFunctionParameterPropertySchema = .init(type: .null)
///
///         let hello: String
///         let world: Int
///     }
///
///     @Parameter(description: "An example description of the custom LLM function parameter type")
///     var customParameter: CustomType
///
///     func execute() async throws -> String {
///         "..."
///     }
/// }
/// ```
public protocol LLMFunctionParameter: Decodable {
    static var schema: LLMFunctionParameterPropertySchema { get }
}
