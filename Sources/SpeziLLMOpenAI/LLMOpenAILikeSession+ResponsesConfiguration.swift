//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import GeneratedOpenAIClient
import OpenAPIRuntime
import SpeziLLM


extension LLMOpenAILikeSession {
    /// Converts the LLMContext to the Responses API input format using `EasyInputMessage` items.
    ///
    /// System messages are excluded, since they instead are passed via the `instructions` field.
    private var responsesInputItems: [Components.Schemas.InputItem] {
        get async {
            await context.compactMap { entity -> Components.Schemas.InputItem? in
                switch entity.role {
                case .system:
                    // System messages go into `instructions`, not input items
                    return nil
                case .user:
                    return .EasyInputMessage(
                        Components.Schemas.EasyInputMessage(
                            role: .user,
                            content: .case1(entity.content)
                        )
                    )
                case .assistant(toolCalls: let toolCalls) where toolCalls.isEmpty:
                    return .EasyInputMessage(
                        Components.Schemas.EasyInputMessage(
                            role: .assistant,
                            content: .case1(entity.content)
                        )
                    )
                case .assistant:
                    // Assistant messages with tool calls are represented by the tool call items themselves,
                    // which are included when we process the subsequent .tool role messages.
                    // Skip the assistant message here to avoid duplication.
                    return nil
                case .tool(id: let functionID, name: _):
                    return .Item(
                        .FunctionCallOutputItemParam(
                            Components.Schemas.FunctionCallOutputItemParam(
                                call_id: functionID,
                                _type: .function_call_output,
                                output: .case1(entity.content)
                            )
                        )
                    )
                case .assistantThinking:
                    // The server retains its own reasoning state via `previous_response_id`; we don't echo
                    // reasoning summaries back as input. They're stored locally for UI display only.
                    return nil
                }
            }
        }
    }

    /// Builds the system instructions string from context system messages.
    private var responsesInstructions: String? {
        get async {
            let systemMessages = await context.filter { $0.role == .system }.map(\.content)
            return systemMessages.isEmpty ? nil : systemMessages.joined(separator: "\n")
        }
    }

    /// Builds the `Operations.createResponse.Input` for the Responses API.
    var openAIResponsesQuery: Operations.createResponse.Input {
        get async throws {
            let tools: [Components.Schemas.Tool] = try schema.functions.values.compactMap { function in
                let functionType = Swift.type(of: function)
                let encodedSchema = try JSONEncoder().encode(try function.schema)
                let jsonObject = try JSONSerialization.jsonObject(with: encodedSchema) as? [String: any Sendable] ?? [:]

                return .FunctionTool(
                    Components.Schemas.FunctionTool(
                        _type: .function,
                        name: functionType.name,
                        description: functionType.description,
                        parameters: try .init(unvalidatedValue: jsonObject),
                        strict: false
                    )
                )
            }

            let input: Components.Schemas.InputParam = .case2(await responsesInputItems)
            let instructions = await responsesInstructions

            let reasoning: Components.Schemas.Reasoning? = schema.parameters.modelType.supportsReasoningSummary
                ? .init(summary: .auto) // QUESTION allow somehow passing in the reasoning level from the outside!!
                : nil

            return Operations.createResponse.Input(
                body: .json(
                    Components.Schemas.CreateResponse(
                        value1: .init(
                            value1: .init(
                                temperature: schema.modelParameters.temperature,
                                top_p: schema.modelParameters.topP
                            ),
                            value2: .init()
                        ),
                        value2: .init(
                            previous_response_id: lastResponseId,
                            model: .init(value1: .init(value1: schema.parameters.modelType.modelId)),
                            reasoning: reasoning,
                            tools: tools.isEmpty ? nil : .init(tools)
                        ),
                        value3: .init(
                            input: input,
                            instructions: instructions,
                            stream: true,
                            max_output_tokens: schema.modelParameters.maxOutputLength
                        )
                    )
                )
            )
        }
    }
}
