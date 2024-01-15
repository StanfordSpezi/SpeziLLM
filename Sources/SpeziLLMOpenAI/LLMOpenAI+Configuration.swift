//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import OpenAI

extension LLMOpenAI {
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
    
    /// Provides the ``LLMOpenAI/context``, the `` LLMOpenAIParameters`` and the ``LLMOpenAIModelParameters`` in an OpenAI `ChatQuery` representation used for querying the API.
    var openAIChatQuery: ChatQuery {
        get async {
            await .init(
                model: self.parameters.modelType,
                messages: self.openAIContext,
                responseFormat: self.modelParameters.responseFormat,
                functions: self.functions.values.compactMap { function in
                    let functionType = Swift.type(of: function)
                    
                    return .init(
                        name: functionType.name,
                        description: functionType.description,
                        parameters: function.schema
                    )
                },
                temperature: self.modelParameters.temperature,
                topP: self.modelParameters.topP,
                n: self.modelParameters.completionsPerOutput,
                stop: self.modelParameters.stopSequence.isEmpty ? nil : self.modelParameters.stopSequence,
                maxTokens: self.modelParameters.maxOutputLength,
                presencePenalty: self.modelParameters.presencePenalty,
                frequencyPenalty: self.modelParameters.frequencyPenalty,
                logitBias: self.modelParameters.logitBias.isEmpty ? nil : self.modelParameters.logitBias,
                user: self.modelParameters.user
            )
        }
    }
}
