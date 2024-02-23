//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import OpenAI


extension LLMOpenAISession {
    /// Map the ``LLMOpenAI/context`` to the OpenAI `[Chat]` representation.
    private var openAIContext: [Chat] {
        get async {
            await self.context.map { chatEntity in
                if case let .function(name: functionName) = chatEntity.role {
                    return Chat(
                        role: chatEntity.role.openAIRepresentation,
                        content: chatEntity.content,
                        name: functionName
                    )
                } else {
                    return Chat(
                        role: chatEntity.role.openAIRepresentation,
                        content: chatEntity.content
                    )
                }
            }
        }
    }
    
    /// Provides the ``LLMOpenAI/context``, the `` LLMOpenAIParameters`` and ``LLMOpenAIModelParameters``, as well as the declared ``LLMFunction``s
    /// in an OpenAI `ChatQuery` representation used for querying the OpenAI API.
    var openAIChatQuery: ChatQuery {
        get async {
            let functions: [ChatFunctionDeclaration] = schema.functions.values.compactMap { function in
                let functionType = Swift.type(of: function)
                
                return .init(
                    name: functionType.name,
                    description: functionType.description,
                    parameters: function.schema
                )
            }
            
            return await .init(
                model: schema.parameters.modelType,
                messages: self.openAIContext,
                responseFormat: schema.modelParameters.responseFormat,
                functions: functions.isEmpty ? nil : functions,
                temperature: schema.modelParameters.temperature,
                topP: schema.modelParameters.topP,
                n: schema.modelParameters.completionsPerOutput,
                stop: schema.modelParameters.stopSequence.isEmpty ? nil : schema.modelParameters.stopSequence,
                maxTokens: schema.modelParameters.maxOutputLength,
                presencePenalty: schema.modelParameters.presencePenalty,
                frequencyPenalty: schema.modelParameters.frequencyPenalty,
                logitBias: schema.modelParameters.logitBias.isEmpty ? nil : schema.modelParameters.logitBias,
                user: schema.modelParameters.user
            )
        }
    }
}
