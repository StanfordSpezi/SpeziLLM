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


extension LLMOpenAILikeSession {
    /// Map the ``LLMOpenAISession/context`` to the OpenAI `[ChatQuery.ChatCompletionMessageParam]` representation.
    private var openAIContext: [Components.Schemas.ChatCompletionRequestMessage] {
        get async {
            await context.map { contextEntity in
                getChatMessage(contextEntity)
            }
        }
    }

    /// Provides the ``LLMOpenAISession/context``, the `` LLMOpenAIParameters`` and ``LLMOpenAIModelParameters``, as well as the declared ``LLMFunction``s
    /// in an OpenAI `Operations.createChatCompletion.Input` representation used for querying the OpenAI API.
    var openAIChatQuery: Operations.createChatCompletion.Input {
        get async throws {
            let tools: Components.Schemas.CreateChatCompletionRequest.Value2Payload.toolsPayload = try schema.functions.values.map { function in
                .ChatCompletionTool(
                    Components.Schemas.ChatCompletionTool(
                        _type: .function,
                        function: Components.Schemas.FunctionObject(
                            description: Swift.type(of: function).description,
                            name: Swift.type(of: function).name,
                            parameters: try function.schema
                        )
                    )
                )
            }

            let modelParameters = schema.modelParameters.accepted(by: schema.parameters.modelType)

            let stop: Components.Schemas.StopConfiguration? = if modelParameters.stopSequence.isEmpty {
                nil
            } else {
                .case2(modelParameters.stopSequence)
            }

            return await Operations.createChatCompletion
                .Input(
                    body: .json(
                        Components.Schemas.CreateChatCompletionRequest(
                            value1: .init(
                                value1: .init(
                                    temperature: modelParameters.temperature,
                                    top_p: modelParameters.topP,
                                    safety_identifier: modelParameters.user
                                ),
                                value2: .init()
                            ),
                            value2: .init(
                                messages: openAIContext,
                                model: .init(value1: schema.parameters.modelType.rawValue),
                                max_completion_tokens: modelParameters.maxOutputLength,
                                frequency_penalty: modelParameters.frequencyPenalty,
                                presence_penalty: modelParameters.presencePenalty,
                                response_format: modelParameters.responseFormat,
                                stream: true,
                                stop: stop,
                                logit_bias: modelParameters.logitBias.additionalProperties.isEmpty
                                    ? nil
                                    : modelParameters.logitBias,
                                n: modelParameters.completionsPerOutput,
                                tools: tools.isEmpty ? nil : tools
                            )
                        )
                    )
                )
        }
    }

    private func getChatMessage(_ contextEntity: LLMContextEntity) -> Components.Schemas.ChatCompletionRequestMessage {
        switch contextEntity.role {
        case let .tool(id: functionID, name: _):
            return .tool(.init(
                role: .tool,
                content: .case1(contextEntity.content),
                tool_call_id: functionID
            ))
        case let .assistant(toolCalls: toolCalls):
            // No function calls present -> regular assistant message
            if toolCalls.isEmpty {
                return .assistant(.init(
                    content: .case1(contextEntity.content),
                    role: .assistant
                ))
            } else {
                // Function calls present
                return .assistant(.init(
                    role: .assistant,
                    tool_calls: toolCalls.map { toolCall in
                        .function(.init(
                            id: toolCall.id,
                            _type: .function,
                            function: .init(name: toolCall.name, arguments: toolCall.arguments)
                        ))
                    }
                ))
            }
        case .system:
            return .system(.init(
                content: .case1(contextEntity.content),
                role: .system
            ))
        case .user:
            if let imageContent = contextEntity._imageContent {
                let imgContent = Components.Schemas.ChatCompletionRequestMessageContentPartImage(
                    _type: .image_url,
                    image_url: .init(url: "data:\(imageContent.contentType);base64,\(imageContent.base64Image)", detail: .low)
                )
                return .user(.init(
                    content: .case2([.ChatCompletionRequestMessageContentPartImage(imgContent)]),
                    role: .user
                ))
            } else {
                return .user(.init(content: .case1(contextEntity.content), role: .user))
            }
        }
    }
}
