//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import OpenAI


/// Helper to process the returned stream by the LLM output generation call, especially in regards to the function call and a possible stop reason
struct LLMOpenAIStreamResult {
    typealias Role = ChatQuery.ChatCompletionMessageParam.Role
    typealias FinishReason = ChatStreamResult.Choice.FinishReason
    
    
    struct FunctionCall {
        var id: String?
        var name: String?
        var arguments: String?
        
        
        init(name: String? = nil, id: String? = nil, arguments: String? = nil) {
            self.name = name
            self.id = id
            self.arguments = arguments
        }
    }
    
    
    var deltaContent: String?
    var role: Role?
    var finishReason: FinishReason?
    var functionCall: [FunctionCall]
    var currentFunctionCallIndex = -1
    
    
    init(deltaContent: String? = nil, role: Role? = nil, finishReason: FinishReason? = nil, functionCall: [FunctionCall] = []) {
        self.deltaContent = deltaContent
        self.role = role
        self.finishReason = finishReason
        self.functionCall = functionCall
    }
    
    
    mutating func append(choice: ChatStreamResult.Choice) -> Self {
        self.deltaContent = choice.delta.content

        if let role = choice.delta.role {
            self.role = role
        }
        
        if let finishReason = choice.finishReason {
            self.finishReason = finishReason
        }
        
        guard let functionCallId = choice.delta.toolCalls?.last?.index else {
            return self
        }
        
        if functionCallId != currentFunctionCallIndex {
            functionCall.append(FunctionCall())
            currentFunctionCallIndex += 1
        }
        
        var newFunctionCall = functionCall[currentFunctionCallIndex]
        
        if let functionCallId = choice.delta.toolCalls?.first?.id {
            newFunctionCall.id = (newFunctionCall.id ?? "") + functionCallId
        }

        if let deltaName = choice.delta.toolCalls?.first?.function?.name {
            newFunctionCall.name = (newFunctionCall.name ?? "") + deltaName
        }

        if let deltaArguments = choice.delta.toolCalls?.first?.function?.arguments {
            newFunctionCall.arguments = (newFunctionCall.arguments ?? "") + deltaArguments
        }
        
        // Only assign back if there were changes
        if choice.delta.toolCalls?.first?.id != nil ||
            choice.delta.toolCalls?.first?.function?.name != nil ||
            choice.delta.toolCalls?.first?.function?.arguments != nil {
            functionCall[currentFunctionCallIndex] = newFunctionCall
        }
        
        return self
    }
}
