//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import OpenAI


extension LLMFogSession {
    typealias Chat = ChatQuery.ChatCompletionMessageParam
    typealias FunctionDeclaration = ChatQuery.ChatCompletionToolParam
    
    
    /// Map the ``LLMFogSession/context`` to the OpenAI `[Chat]` representation.
    private var openAIContext: [Chat] {
        get async {
            await self.context.compactMap { contextEntity in
                Chat(
                    role: contextEntity.role.openAIRepresentation,
                    content: contextEntity.content
                )
            }
        }
    }
    
    /// Provides the ``LLMFogSession/context``, the `` LLMFogParameters`` and ``LLMFogModelParameters``
    /// in an OpenAI `ChatQuery` representation used for querying the Fog LLM API.
    var openAIChatQuery: ChatQuery {
        get async {
            await .init(
                messages: self.openAIContext,
                model: schema.parameters.modelType.rawValue,
                frequencyPenalty: schema.modelParameters.frequencyPenalty,
                maxTokens: schema.modelParameters.maxOutputLength,
                presencePenalty: schema.modelParameters.presencePenalty,
                responseFormat: schema.modelParameters.responseFormat,
                seed: schema.modelParameters.seed,
                stop: .stringList(schema.modelParameters.stopSequence),
                temperature: schema.modelParameters.temperature,
                topP: schema.modelParameters.topP
            )
        }
    }
}
