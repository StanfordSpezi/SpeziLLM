//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import OpenAPIRuntime
import SpeziLLM


extension LLMFogSession {
    /// Map the ``LLMFogSession/context`` to the OpenAI `[ChatQuery.ChatCompletionMessageParam]` representation.
    private var openAIContext: [Components.Schemas.ChatCompletionRequestMessage] {
        get async {
            await context.compactMap { contextEntity in
                getChatMessage(contextEntity)
            }
        }
    }

    /// Provides the ``LLMFogSession/context``, the `` LLMFogParameters`` and ``LLMFogModelParameters``
    /// in an OpenAI `Operations.createChatCompletion.Input` representation used for querying the Fog LLM API.
    var openAIChatQuery: Operations.createChatCompletion.Input {
        get async {
            await .init(
                body: .json(
                    LLMFogRequestType(
                        messages: openAIContext,
                        model: schema.parameters.modelType,
                        frequency_penalty: schema.modelParameters.frequencyPenalty,
                        logit_bias: nil,
                        max_tokens: schema.modelParameters.maxOutputLength,
                        n: nil,
                        presence_penalty: schema.modelParameters.presencePenalty,
                        response_format: schema.modelParameters.responseFormat,
                        seed: schema.modelParameters.seed,
                        stop: LLMFogRequestType.stopPayload.case2(schema.modelParameters.stopSequence),
                        stream: true,
                        temperature: schema.modelParameters.temperature,
                        top_p: schema.modelParameters.topP,
                        tools: nil,
                        user: nil
                    )
                )
            )
        }
    }


    private func getChatMessage(_ contextEntity: LLMContextEntity) -> Components.Schemas.ChatCompletionRequestMessage? {
        switch contextEntity.role {
        case let .tool(id: functionID, name: _):
            return Components.Schemas.ChatCompletionRequestMessage.ChatCompletionRequestToolMessage(.init(
                role: .tool,
                content: contextEntity.content,
                tool_call_id: functionID
            ))
        case let .assistant(toolCalls: toolCalls):
            // No function calls present -> regular assistant message
            if toolCalls.isEmpty {
                return Components.Schemas.ChatCompletionRequestMessage.ChatCompletionRequestAssistantMessage(.init(
                    content: contextEntity.content,
                    role: .assistant
                ))
            } else {
                // Function calls present
                return Components.Schemas.ChatCompletionRequestMessage.ChatCompletionRequestAssistantMessage(.init(
                    role: .assistant,
                    tool_calls: toolCalls.map { toolCall in
                            .init(
                                id: toolCall.id,
                                _type: .function,
                                function: .init(name: toolCall.name, arguments: toolCall.arguments)
                            )
                    }
                ))
            }
        case .system:
            // No function calls present -> regular assistant message
            guard let role = Components.Schemas.ChatCompletionRequestSystemMessage
                .rolePayload(rawValue: contextEntity.role.openAIRepresentation.rawValue)
            else {
                Self.logger.error("Could not create ChatCompletionRequestSystemMessage payload")
                return nil
            }
            return Components.Schemas.ChatCompletionRequestMessage.ChatCompletionRequestSystemMessage(
                .init(
                    content: contextEntity.content,
                    role: role
                )
            )
        case .user:
            return Components.Schemas.ChatCompletionRequestMessage
                .ChatCompletionRequestUserMessage(.init(content: .case1(contextEntity.content), role: .user))
        }
    }
}
