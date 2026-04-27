//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import GeneratedOpenAIClient
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
                    Components.Schemas.CreateChatCompletionRequest(
                        value1: .init(
                            value1: .init(
                                temperature: schema.modelParameters.temperature,
                                top_p: schema.modelParameters.topP
                            ),
                            value2: .init()
                        ),
                        value2: .init(
                            messages: openAIContext,
                            model: .init(value1: schema.parameters.modelType),
                            max_completion_tokens: schema.modelParameters.maxOutputLength,
                            frequency_penalty: schema.modelParameters.frequencyPenalty,
                            presence_penalty: schema.modelParameters.presencePenalty,
                            response_format: schema.modelParameters.responseFormat,
                            stream: true,
                            stop: .case2(schema.modelParameters.stopSequence)
                        )
                    )
                )
            )
        }
    }


    private func getChatMessage( // swiftlint:disable:this function_body_length
        _ contextEntity: LLMContextEntity
    ) -> Components.Schemas.ChatCompletionRequestMessage? {
        switch contextEntity.role {
        case let .toolCallResponse(id: functionID, name: _):
            return Components.Schemas.ChatCompletionRequestMessage.ChatCompletionRequestToolMessage(.init(
                role: .tool,
                content: .case1(contextEntity.content),
                tool_call_id: functionID
            ))
        case .assistant:
            return Components.Schemas.ChatCompletionRequestMessage.ChatCompletionRequestAssistantMessage(.init(
                content: .case1(contextEntity.content),
                role: .assistant
            ))
        case .toolCalls(let toolCalls):
            return Components.Schemas.ChatCompletionRequestMessage.ChatCompletionRequestAssistantMessage(.init(
                role: .assistant,
                tool_calls: toolCalls.map { toolCall in
                    .ChatCompletionMessageToolCall(
                        .init(
                            id: toolCall.id,
                            _type: .function,
                            function: .init(name: toolCall.name, arguments: toolCall.arguments)
                        )
                    )
                }
            ))
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
                    content: .case1(contextEntity.content),
                    role: role
                )
            )
        case .user:
            if let imageContent = contextEntity._imageContent {
                let imgPayload = Components.Schemas.ChatCompletionRequestMessageContentPartImage
                    .image_urlPayload(url: .init("data:\(imageContent.contentType);base64,\(imageContent.base64Image)"))
                let imgContent = Components.Schemas.ChatCompletionRequestMessageContentPartImage(
                    _type: .image_url,
                    image_url: imgPayload
                )
                return Components.Schemas.ChatCompletionRequestMessage
                    .ChatCompletionRequestUserMessage(.init(content: .case2([
                        .ChatCompletionRequestMessageContentPartImage(imgContent)
                    ]), role: .user))
            } else {
                return Components.Schemas.ChatCompletionRequestMessage
                    .ChatCompletionRequestUserMessage(.init(content: .case1(contextEntity.content), role: .user))
            }
        case .assistantThinking:
            // Reasoning summaries are local UI artifacts; the Chat Completions API has no input slot for them.
            return nil
        }
    }
}
