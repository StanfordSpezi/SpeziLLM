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
    /// Builds a `Operations.createResponse.Input` for the Responses API.
    func openAIResponsesQuery() async throws -> Operations.createResponse.Input {
        let context = await context
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
        let instructions: String = context.lazy
            .compactMap { $0.role == .system ? $0.content : nil }
            .joined(separator: "\n\n")
        let reasoning: Components.Schemas.Reasoning? = schema.parameters.modelType.supportsReasoningSummary
            ? .init(summary: .auto) // maybe allow somehow passing in the reasoning level from the outside!!
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
                        input: .case2(context.compactMap { $0.toResponsesInputItem() }),
                        instructions: instructions.isEmpty ? nil : instructions,
                        stream: true,
                        max_output_tokens: schema.modelParameters.maxOutputLength
                    )
                )
            )
        )
    }
}


extension LLMContextEntity {
    /// Converts the `LLMContextEntity` to the a Responses API input item.
    ///
    /// System messages are excluded, since they instead are passed via the `instructions` field.
    fileprivate func toResponsesInputItem() -> Components.Schemas.InputItem? {
        switch self.role {
        case .system:
            // System messages go into `instructions`, not input items
            return nil
        case .user:
            return .EasyInputMessage(
                Components.Schemas.EasyInputMessage(
                    role: .user,
                    content: .case1(self.content)
                )
            )
        case .assistant:
            return .EasyInputMessage(
                Components.Schemas.EasyInputMessage(
                    role: .assistant,
                    content: .case1(self.content)
                )
            )
        case .toolCalls:
            // Assistant messages with tool calls are represented by the tool call items themselves,
            // which are included when we process the subsequent .tool role messages.
            // Skip the assistant message here to avoid duplication.
            return nil
        case .toolCallResponse(id: let functionID, name: _):
            return .Item(
                .FunctionCallOutputItemParam(
                    Components.Schemas.FunctionCallOutputItemParam(
                        call_id: functionID,
                        _type: .function_call_output,
                        output: .case1(self.content)
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
