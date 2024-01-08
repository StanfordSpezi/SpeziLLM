//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import OpenAI


class LLMStreamResult {
    class FunctionCall {
        var name: String?
        var arguments: String?
        
        
        init(name: String? = nil, arguments: String? = nil) {
            self.name = name
            self.arguments = arguments
        }
    }
    
    
    let id: Int
    var content: String?
    var role: Chat.Role?
    var functionCall: FunctionCall?
    var finishReason: String?
    
    
    init(id: Int, content: String? = nil, role: Chat.Role? = nil, functionCall: FunctionCall? = nil, finishReason: String? = nil) {
        self.id = id
        self.content = content
        self.role = role
        self.functionCall = functionCall
        self.finishReason = finishReason
    }
    
    
    func append(choice: ChatStreamResult.Choice) {
        if let deltaContent = choice.delta.content {
            self.content = (self.content ?? "").appending(deltaContent)
        }
        
        if let role = choice.delta.role {
            self.role = role
        }
        
        if let deltaName = choice.delta.functionCall?.name {
            functionCall = functionCall ?? LLMStreamResult.FunctionCall()
            functionCall?.name = (functionCall?.name ?? "").appending(deltaName)
        }
        
        if let deltaArguments = choice.delta.functionCall?.arguments {
            functionCall = functionCall ?? LLMStreamResult.FunctionCall()
            functionCall?.arguments = (functionCall?.arguments ?? "").appending(deltaArguments)
        }
        
        if let finishReason = choice.finishReason {
            self.finishReason = (self.finishReason ?? "").appending(finishReason)
        }
    }
}
