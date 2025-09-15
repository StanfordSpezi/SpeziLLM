//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation

/// Represents LLM function calling parameters in the shape of an `String`-based `enum`.
///
/// In order to map a `String`-based Swift `enum` to a function calling parameter, developers must conform `enum`s to the ``LLMFunctionParameterEnum`` protocol.
/// This enables ``SpeziLLMOpenAI`` to automatically synthezise the OpenAI function calling schema from the `String`-based `enum`.
///
/// > Important: The developer-defined `enum` has to have a `RawValue` of type `String`.
///
/// The ``LLMFunctionParameterEnum`` enforces conformance to the following protocols, ensuring that all `enum` cases can be iterated over and
/// represented by a raw type, as well as the ability to decode the `enum` from `Data`: `CaseIterable`, `RawRepresentable`, and `Decodable`.
///
/// # Usage
///
/// An example usage of the ``LLMFunctionParameterEnum`` for a `String`-based `enum`  type:
///
/// ```swift
/// struct LLMOpenAIFunctionWeather: LLMFunction {
///     /// Manual conformance to `LLMFunctionParameterEnum`.
///     enum TemperatureUnit: String, LLMFunctionParameterEnum {
///         case celsius
///         case fahrenheit
///     }
///
///     // ...
///
///     @Parameter(description: "The unit of the temperature")
///     var unit: TemperatureUnit
///
///
///     func execute() async throws -> String? {
///         "..."
///     }
/// }
/// ```
public protocol LLMFunctionParameterEnum: CaseIterable, RawRepresentable, Decodable {}
