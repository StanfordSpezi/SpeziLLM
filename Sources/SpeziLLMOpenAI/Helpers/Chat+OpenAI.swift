//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import GeneratedOpenAIClient
import OpenAPIRuntime
import SpeziLLM


extension LLMContextEntity.Role {
    typealias Role = Components.Schemas.ChatCompletionRole


    /// Maps the `LLMContextEntity/Role`s to the `OpenAI/Chat/Role`s.
    var openAIRepresentation: Role {
        switch self {
        case .assistant: .assistant
        case .user: .user
        case .system: .system
        case .tool: .tool
        }
    }
}
