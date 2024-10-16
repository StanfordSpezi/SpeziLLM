//
//  ModelConfiguration+PromptFormat.swift
//  SpeziLLM
//
//  Created by Leon Nissen on 10/15/24.
//

import MLXLLM


extension ModelConfiguration {
    var foo: String {
        switch self.name {
        case ModelConfiguration.codeLlama13b4bit.name:
            return ""
        default:
            return ""
        }
    }
}
