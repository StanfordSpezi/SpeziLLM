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
    struct FunctionCall {
        var name: String?
        var arguments: String?
        
        
        init(name: String? = nil, arguments: String? = nil) {
            self.name = name
            self.arguments = arguments
        }
    }
    
    
    var deltaContent: String?
    var role: Chat.Role?
    var functionCall: FunctionCall?
    private var finishReasonBase: String?
    var finishReason: LLMOpenAIFinishReason {
        guard let finishReasonBase else {
            return .null
        }
        
        return .init(rawValue: finishReasonBase) ?? .null
    }
    
    
    init(deltaContent: String? = nil, role: Chat.Role? = nil, functionCall: FunctionCall? = nil, finishReason: String? = nil) {
        self.deltaContent = deltaContent
        self.role = role
        self.functionCall = functionCall
        self.finishReasonBase = finishReason
    }
    
    
    mutating func append(choice: ChatStreamResult.Choice) -> Self {
        self.deltaContent = choice.delta.content

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

        if let finishReasonBase = choice.finishReason {
            self.finishReasonBase = (self.finishReasonBase ?? "") + finishReasonBase
        }
        
        return self
    }
}
