//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import OpenAPIRuntime
import SpeziLLM

extension LLMOpenAISession {
    // FIXME: Reduce function length by adding type aliases
    // swiftlint:disable function_body_length
    private func getChatMessage(_ contextEntity: LLMContextEntity) -> Components.Schemas.ChatCompletionRequestMessage? {
        switch contextEntity.role {
        case let .tool(id: functionID, name: _):
            guard let role = Components.Schemas.ChatCompletionRequestToolMessage
                .rolePayload(rawValue: contextEntity.role.openAIRepresentation.rawValue)
            else {
                Self.logger.error("Could not create ChatCompletionRequestToolMessage payload")
                return nil
            }
            let msg = Components.Schemas.ChatCompletionRequestToolMessage(
                role: role,
                content: contextEntity.content,
                tool_call_id: functionID
            )
            return Components.Schemas.ChatCompletionRequestMessage.ChatCompletionRequestToolMessage(msg)
        case let .assistant(toolCalls: toolCalls):
            // No function calls present -> regular assistant message
            guard let role = Components.Schemas.ChatCompletionRequestAssistantMessage
                .rolePayload(rawValue: contextEntity.role.openAIRepresentation.rawValue)
            else {
                Self.logger.error("Could not create ChatCompletionRequestAssistantMessage role")
                return nil
            }
            if toolCalls.isEmpty {
                let msg = Components.Schemas.ChatCompletionRequestAssistantMessage(
                    content: contextEntity.content,
                    role: role
                )
                return Components.Schemas.ChatCompletionRequestMessage.ChatCompletionRequestAssistantMessage(msg)
            } else {
                // Function calls present
                let msg = Components.Schemas.ChatCompletionRequestAssistantMessage(
                    role: role,
                    tool_calls: toolCalls.compactMap { toolCall in
                        guard let type = Components.Schemas.ChatCompletionMessageToolCall
                            ._typePayload(rawValue: toolCall.type)
                        else {
                            Self.logger.error("Could not create ChatCompletionRequestAssistantMessage type")
                            return nil
                        }
                        return .init(
                            id: toolCall.id,
                            _type: type,
                            function: .init(name: toolCall.name, arguments: toolCall.arguments)
                        )
                    }
                )
                return Components.Schemas.ChatCompletionRequestMessage.ChatCompletionRequestAssistantMessage(msg)
            }
        case .system:
            // No function calls present -> regular assistant message
            guard let role = Components.Schemas.ChatCompletionRequestSystemMessage
                .rolePayload(rawValue: contextEntity.role.openAIRepresentation.rawValue)
            else {
                Self.logger.error("Could not create ChatCompletionRequestSystemMessage payload")
                return nil
            }
            let msg = Components.Schemas.ChatCompletionRequestSystemMessage(
                content: contextEntity.content,
                role: role
            )
            return Components.Schemas.ChatCompletionRequestMessage.ChatCompletionRequestSystemMessage(msg)
        case .user:
            guard let role = Components.Schemas.ChatCompletionRequestUserMessage
                .rolePayload(rawValue: contextEntity.role.openAIRepresentation.rawValue)
            else {
                Self.logger.error("Could not create ChatCompletionRequestUserMessage payload")
                return nil
            }
            let msg = Components.Schemas.ChatCompletionRequestUserMessage(
                content: Components.Schemas.ChatCompletionRequestUserMessage.contentPayload
                    .case1(contextEntity.content),
                role: role
            )
            return Components.Schemas.ChatCompletionRequestMessage.ChatCompletionRequestUserMessage(msg)
        }
    }

    /// Map the ``LLMOpenAISession/context`` to the OpenAI `[ChatQuery.ChatCompletionMessageParam]` representation.
    private var openAIContext: [Components.Schemas.ChatCompletionRequestMessage] {
        get async {
            await context.compactMap { contextEntity in
                getChatMessage(contextEntity)
            }
        }
    }

    /// Provides the ``LLMOpenAISession/context``, the `` LLMOpenAIParameters`` and ``LLMOpenAIModelParameters``, as well as the declared ``LLMFunction``s
    /// in an OpenAI `ChatQuery` representation used for querying the OpenAI API.
    var openAIChatQuery: Operations.createChatCompletion.Input {
        get async {
            let functions: [Components.Schemas.ChatCompletionTool] = schema.functions.values.compactMap { function in
                Components.Schemas.ChatCompletionTool(
                    _type: .function,
                    function: Components.Schemas.FunctionObject(
                        description: Swift.type(of: function).description,
                        name: Swift.type(of: function).name,
                        parameters: function.schema
                    )
                )
            }

            return await Operations.createChatCompletion
                .Input(body: .json(Components.Schemas.CreateChatCompletionRequest(
                    messages: openAIContext,
                    model: schema.parameters.modelType,
                    frequency_penalty: schema.modelParameters.frequencyPenalty,
                    logit_bias: schema.modelParameters.logitBias.additionalProperties.isEmpty ? nil : schema
                        .modelParameters
                        .logitBias,
                    max_tokens: schema.modelParameters.maxOutputLength,
                    n: schema.modelParameters.completionsPerOutput,
                    presence_penalty: schema.modelParameters.presencePenalty,
                    response_format: schema.modelParameters.responseFormat,
                    seed: schema.modelParameters.seed,
                    stop: Components.Schemas.CreateChatCompletionRequest.stopPayload
                        .case2(schema.modelParameters.stopSequence),
                    stream: true,
                    temperature: schema.modelParameters.temperature,
                    top_p: schema.modelParameters.topP,
                    tools: functions.isEmpty ? nil : functions,
                    user: schema.modelParameters.user
                )))
        }
    }
}
