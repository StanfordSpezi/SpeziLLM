//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import OpenAI


extension LLMOpenAISession {
    typealias Chat = ChatQuery.ChatCompletionMessageParam
    typealias FunctionDeclaration = ChatQuery.ChatCompletionToolParam
    
    
    /// Map the ``LLMOpenAISession/context`` to the OpenAI `[ChatQuery.ChatCompletionMessageParam]` representation.
    private var openAIContext: [Chat] {
        get async {
            await self.context.compactMap { contextEntity in
                if case let .tool(id: functionId, name: functionName) = contextEntity.role {
                    Chat(
                        role: contextEntity.role.openAIRepresentation,
                        content: contextEntity.content,
                        name: functionName,
                        toolCallId: functionId
                    )
                } else if case let .assistant(toolCalls: toolCalls) = contextEntity.role {
                    // No function calls present -> regular assistant message
                    if toolCalls.isEmpty {
                        Chat(
                            role: contextEntity.role.openAIRepresentation,
                            content: contextEntity.content
                        )
                    // Function calls present
                    } else {
                        Chat(
                            role: contextEntity.role.openAIRepresentation,
                            toolCalls: toolCalls.map { toolCall in
                                .init(
                                    id: toolCall.id,
                                    function: .init(arguments: toolCall.arguments, name: toolCall.name)
                                )
                            }
                        )
                    }
                } else {
                    Chat(
                        role: contextEntity.role.openAIRepresentation,
                        content: contextEntity.content
                    )
                }
            }
        }
    }
    
    /// Provides the ``LLMOpenAISession/context``, the `` LLMOpenAIParameters`` and ``LLMOpenAIModelParameters``, as well as the declared ``LLMFunction``s
    /// in an OpenAI `ChatQuery` representation used for querying the OpenAI API.
    var openAIChatQuery: ChatQuery {
        get async {
            let functions: [FunctionDeclaration] = schema.functions.values.compactMap { function in
                let functionType = Swift.type(of: function)
                
                return .init(function: .init(
                    name: functionType.name,
                    description: functionType.description,
                    parameters: function.schema
                ))
            }
            
            return await ChatQuery(
                messages: self.openAIContext,
                model: schema.parameters.modelType,
                frequencyPenalty: schema.modelParameters.frequencyPenalty,
                logitBias: schema.modelParameters.logitBias.isEmpty ? nil : schema.modelParameters.logitBias,
                maxTokens: schema.modelParameters.maxOutputLength,
                n: schema.modelParameters.completionsPerOutput,
                presencePenalty: schema.modelParameters.presencePenalty,
                responseFormat: schema.modelParameters.responseFormat,
                seed: schema.modelParameters.seed,
                stop: .stringList(schema.modelParameters.stopSequence),
                temperature: schema.modelParameters.temperature,
                tools: functions.isEmpty ? nil : functions,
                topP: schema.modelParameters.topP,
                user: schema.modelParameters.user,
                stream: true
            )
        }
    }
}
