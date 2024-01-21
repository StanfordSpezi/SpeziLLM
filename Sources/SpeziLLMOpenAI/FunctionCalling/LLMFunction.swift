//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


/// Represents an OpenAI Function that can be called by a GPT-based LLM.
///
/// The `LLMFunction` is the Spezi-based implementation of an OpenAI LLM function (or tool): https://platform.openai.com/docs/guides/function-calling <!-- markdown-link-check-disable-line -->
/// It enables a structured, bidirectional, and reliable communication between the OpenAI LLMs and external tools, such as the Spezi ecosystem.
///
/// Upon initializing the ``LLMOpenAI``, developers can pass an array of ``LLMFunction``s via ``LLMOpenAI/init(parameters:modelParameters:_:)``.
/// These functions are then made available to OpenAI's GPT models and can be called if the model decides to do so, based on the current conversational context.
/// An ``LLMFunction`` can have multiple ``LLMFunction/Parameter``s (`@Parameter`) to tailor the requested functionality of the LLM.
///
/// The crucial properties of a ``LLMFunction`` are the ``LLMFunction/name``, serving as the identifier of the function, as well as the ``LLMFunction/description``,
/// enabling the LLM to understand the purpose of the available function call.
/// The actual logic that is executed upon a function call by the LLM resides in the ``LLMFunction/execute()`` function.
/// ``LLMFunction/execute()`` returns a `String?`, containing all the information the Spezi application wants to provide to the LLM upon a function call,
/// and is automatically injected into the LLM conversation by `SpeziLLM`. In case of a `nil` return value, the function call completion is automatically injected into the LLM conversation.
///
/// The ``LLMFunction`` can get dependencies injected by the initializing component (e.g., a `View`) via a custom-implemented initializer.
/// The protocol puts no requirements upon the shape of the initializer, enabling developers to pass in arbitrary dependencies necessary to perform the logic of the ``LLMFunction``.
///
/// # Usage
///
/// The code below demonstrates a short example of the base usage of ``LLMFunction``s with ``LLMOpenAI``.
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
///     private let model = LLMOpenAI(
///         parameters: .init(
///             modelType: .gpt4_1106_preview,
///             systemPrompt: "You're a helpful assistant that answers questions from users."
///         )
///     ) {
///         WeatherFunction()   // State which LLM functions are made available to the OpenAI LLM
///     }
///
///     var body: some View {
///         LLMChatView(
///             model: model
///         )
///     }
/// }
/// ```
public protocol LLMFunction {
    /// The name of the LLM function that is called, serves as the main identifier of the function.
    static var name: String { get }
    /// The description of the LLM function, enabling the LLM to understand the purpose of the function.
    static var description: String { get }
    
    
    /// Performs the logic that is executed when the LLM calls a specific function.
    /// The output is automatically injected into the conversational history.
    ///
    /// - Returns: `String`-based output of the function call that is then provided to the LLM. Can be `nil`.
    func execute() async throws -> String?
}
