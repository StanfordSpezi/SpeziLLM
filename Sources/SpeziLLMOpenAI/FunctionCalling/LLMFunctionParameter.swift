//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// Represents an LLM function calling parameter.
///
/// The ``LLMFunctionParameter``enables developers to manually specify the conformance of Swift types to the [OpenAI Function calling schema](https://platform.openai.com/docs/guides/function-calling).
/// However, the usage of ``LLMFunctionParameter`` should rarely be required as ``SpeziLLMOpenAI`` automatically synthezises the OpenAI schema from the underlying primitive Swift types,
/// such as `Int`s, `Float`s, `Double`s, `Bool`s, and `String`s. Furthermore, `array`- or `enum`-based compositions of these type are automatically supported, similar to `Optional`s of these types.
///
/// The protocol enforces the ``LLMFunctionParameter/schema`` property that defines the OpenAI schema-based structure of the function calling arguments,
/// enabling developers full freedom over the defined schema.
///
/// > Warning: One cannot use the ``LLMFunctionParameter`` to nest OpenAI schema `object`s within `object`s, as the defining OpenAI schema language doesn't allow for that.
/// > In case your LLM function calling use case requires such functionality, please rethink your approach and try to simplify it.
///
/// # Usage
///
/// An example usage of the ``LLMFunctionParameter`` for a custom type looks like the following:
///
/// ```swift
/// /// Manual conformance to `LLMFunctionParameter` of a custom type.
/// extension Data: LLMFunctionParameter {
///     public static var schema: LLMFunctionParameterPropertySchema {
///         .init(type: .string)
///     }
/// }
///
/// struct WeatherFunction: LLMFunction {
///     @Parameter(description: "Random base64 coded data")
///     var customParameter: Data
///
///     func execute() async throws -> String {
///         "..."
///     }
/// }
/// ```
public protocol LLMFunctionParameter: Decodable {
    static var schema: LLMFunctionParameterPropertySchema { get }
}
