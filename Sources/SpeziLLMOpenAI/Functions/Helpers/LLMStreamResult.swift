//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import OpenAI


struct LLMStreamResult {
    struct FunctionCall {
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
    
    
    mutating func append(choice: ChatStreamResult.Choice) {
        if let deltaContent = choice.delta.content {
            self.content = (self.content ?? "") + deltaContent
        }

        if let role = choice.delta.role {
            self.role = role
        }

        var newFunctionCall = self.functionCall ?? FunctionCall()

        if let deltaName = choice.delta.functionCall?.name {
            newFunctionCall.name = (self.functionCall?.name ?? "") + deltaName
        }

        if let deltaArguments = choice.delta.functionCall?.arguments {
            newFunctionCall.arguments = (self.functionCall?.arguments ?? "") + deltaArguments
        }
        
        // Only assign back if there were changes
        if choice.delta.functionCall?.name != nil || choice.delta.functionCall?.arguments != nil {
            self.functionCall = newFunctionCall
        }

        if let finishReason = choice.finishReason {
            self.finishReason = (self.finishReason ?? "") + finishReason
        }
    }
}
