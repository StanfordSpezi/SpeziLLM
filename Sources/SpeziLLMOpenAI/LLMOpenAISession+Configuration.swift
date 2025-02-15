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
    /// Map the ``LLMOpenAISession/context`` to the OpenAI `[ChatQuery.ChatCompletionMessageParam]` representation.
    private var openAIContext: [Components.Schemas.ChatCompletionRequestMessage] {
        get async {
            await context.compactMap { contextEntity in
                getChatMessage(contextEntity)
            }
        }
    }

    /// Provides the ``LLMOpenAISession/context``, the `` LLMOpenAIParameters`` and ``LLMOpenAIModelParameters``, as well as the declared ``LLMFunction``s
    /// in an OpenAI `Operations.createChatCompletion.Input` representation used for querying the OpenAI API.
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
                .Input(
                    body: .json(
                        LLMOpenAIRequestType(
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
                            stop: LLMOpenAIRequestType.stopPayload.case2(schema.modelParameters.stopSequence),
                            stream: true,
                            temperature: schema.modelParameters.temperature,
                            top_p: schema.modelParameters.topP,
                            tools: functions.isEmpty ? nil : functions,
                            user: schema.modelParameters.user
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
