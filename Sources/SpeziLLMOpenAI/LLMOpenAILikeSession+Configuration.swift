//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import GeneratedOpenAIClient
import OpenAPIRuntime
import OSLog
import SpeziLLM


extension LLMOpenAILikeSession {
    /// Provides the ``LLMOpenAISession/context``, the `` LLMOpenAIParameters`` and ``LLMOpenAIModelParameters``, as well as the declared ``LLMFunction``s
    /// in an OpenAI `Operations.createChatCompletion.Input` representation used for querying the OpenAI API.
    func openAIChatQuery() async throws -> Operations.createChatCompletion.Input {
        let context = await context
        let functions: [Components.Schemas.CreateChatCompletionRequest.Value2Payload.toolsPayloadPayload] =
            try schema.functions.values.compactMap { function in
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
        let stop: Components.Schemas.StopConfiguration? = if schema.modelParameters.stopSequence.isEmpty {
            nil
        } else {
            .case2(schema.modelParameters.stopSequence)
        }
        return Operations.createChatCompletion.Input(
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
                        messages: context.compactMap { $0.toChatMessage(logger: Self.logger) },
                        model: .init(value1: schema.parameters.modelType.modelId),
                        max_completion_tokens: schema.modelParameters.maxOutputLength,
                        frequency_penalty: schema.modelParameters.frequencyPenalty,
                        presence_penalty: schema.modelParameters.presencePenalty,
                        response_format: schema.modelParameters.responseFormat,
                        stream: true,
                        stop: stop,
                        logit_bias: schema.modelParameters.logitBias.additionalProperties.isEmpty ? nil : schema
                            .modelParameters
                            .logitBias,
                        n: schema.modelParameters.completionsPerOutput,
                        tools: functions.isEmpty ? nil : functions,
                        tool_choice: nil
                    )
                )
            )
        )
    }
}


extension LLMContextEntity {
    fileprivate func toChatMessage(logger: Logger) -> Components.Schemas.ChatCompletionRequestMessage? { // swiftlint:disable:this function_body_length
        switch self.role {
        case let .toolCallResponse(id: functionID, name: _):
            return Components.Schemas.ChatCompletionRequestMessage.ChatCompletionRequestToolMessage(.init(
                role: .tool,
                content: .case1(self.content),
                tool_call_id: functionID
            ))
        case .assistant:
            return Components.Schemas.ChatCompletionRequestMessage.ChatCompletionRequestAssistantMessage(.init(
                content: .case1(self.content),
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
            guard let role = Components.Schemas.ChatCompletionRequestSystemMessage
                .rolePayload(rawValue: self.role.openAIRepresentation.rawValue)
            else {
                logger.error("Could not create ChatCompletionRequestSystemMessage payload")
                return nil
            }
            return Components.Schemas.ChatCompletionRequestMessage.ChatCompletionRequestSystemMessage(
                .init(
                    content: .case1(self.content),
                    role: role
                )
            )
        case .user:
            if let imageContent = self._imageContent {
                let imgPayload = Components.Schemas.ChatCompletionRequestMessageContentPartImage
                    .image_urlPayload(url: .init("data:\(imageContent.contentType);base64,\(imageContent.base64Image)"), detail: .low)
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
                    .ChatCompletionRequestUserMessage(.init(content: .case1(self.content), role: .user))
            }
        case .assistantThinking:
            // Reasoning summaries are local UI artifacts; the Chat Completions API has no input slot for them.
            return nil
        }
    }
}
