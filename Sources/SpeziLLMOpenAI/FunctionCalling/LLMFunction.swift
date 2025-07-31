//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


/// Represents an OpenAI Function that can be called by a GPT-based LLM.
///
/// The `LLMFunction` is the Spezi-based implementation of an [OpenAI LLM function](https://platform.openai.com/docs/guides/function-calling).  <!-- markdown-link-check-disable-line -->
/// It enables a structured, bidirectional, and reliable communication between the OpenAI LLMs and external tools, such as the Spezi ecosystem.
///
/// Upon initializing the ``LLMOpenAISchema``, developers can pass an array of ``LLMFunction``s via ``LLMOpenAISchema/init(parameters:modelParameters:injectIntoContext:_:)``.
/// These functions are then made available to OpenAI's GPT models and can be called if the model decides to do so, based on the current conversational context.
/// An ``LLMFunction`` can have multiple ``LLMFunction/Parameter``s (`@Parameter`) to tailor the requested functionality of the LLM.
///
/// The crucial properties of a ``LLMFunction`` are the ``LLMFunction/name``, serving as the identifier of the function, as well as the ``LLMFunction/description``,
/// enabling the LLM to understand the purpose of the available function call.
/// The actual logic that is executed upon a function call by the LLM resides in the ``LLMFunction/execute()`` function.
/// ``LLMFunction/execute()`` returns a `String?`, containing all the information the Spezi application wants to provide to the LLM upon a function call,
/// and is automatically injected into the LLM conversation by `SpeziLLM`.
/// In case of a `nil` return value, indicating a successful function run without producing any actionable output, a text indicating the function call completion is automatically injected into the LLM conversation.
/// Don't use the `nil` return value as an escape hatch to return no proper value in case of an exception within the function. Either properly handle the exception directly within the ``LLMFunction`` or rethrow the exception.
/// The rethrown exception will then be handled by ``SpeziLLMOpenAI`` and surfaced to the user.
///
/// The ``LLMFunction`` can get dependencies injected by the initializing component (e.g., a `View`) via a custom-implemented initializer.
/// The protocol puts no requirements upon the shape of the initializer, enabling developers to pass in arbitrary dependencies necessary to perform the logic of the ``LLMFunction``.
///
/// # Usage
///
/// The code below demonstrates a short example of the base usage of ``LLMFunction``s with ``LLMOpenAISchema``.
/// In case the user asks the LLM about the weather in a specific location, the LLM will request to call the `WeatherFunction` to provide a (in this example dummy) weather reading.
///
/// ```swift
/// // The defined `LLMFunction` made available to the OpenAI LLM
/// struct WeatherFunction: LLMFunction {
///     static let name: String = "get_current_weather"
///     static let description: String = "Get the current weather in a given location"
///
///     @Parameter(description: "The city and state of the to be determined weather, e.g. San Francisco, CA")
///     var location: String
///
///     func execute() async throws -> String? {
///         "The weather at \(location) is 30 degrees"
///     }
/// }
///
/// // Enclosing view to display an LLM chat
/// struct LLMOpenAIChatTestView: View {
///     private let schema = LLMOpenAISchema(
///         parameters: .init(
///             modelType: .gpt4o,
///             systemPrompt: "You're a helpful assistant that answers questions from users."
///         )
///     ) {
///         WeatherFunction()   // State which LLM functions are made available to the OpenAI LLM
///     }
///
///     var body: some View {
///         LLMChatView(
///             schema: schema
///         )
///     }
/// }
/// ```
public protocol LLMFunction: Sendable {
    /// The name of the LLM function that is called, serves as the main identifier of the function.
    static var name: String { get }
    /// The description of the LLM function, enabling the LLM to understand the purpose of the function.
    static var description: String { get }
    
    
    /// Performs the logic that is executed when the LLM calls a specific function.
    /// The output is automatically injected into the conversational history.
    ///
    /// - Returns: `String`-based output of the function call that is then provided to the LLM.
    ///            Can be `nil`, indicating the function ran successfully but didn't produce any actionable output that should be passed to the LLM.
    ///            In case of an exception within the function, don't use the `nil` return value but throw a proper exception that will be surfaced to the user by ``SpeziLLMOpenAI``.
    func execute() async throws -> String?
}
