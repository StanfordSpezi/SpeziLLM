//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziChat


extension Chat {
    /// Append an `ChatEntity/Role/assistant` output to the `Chat`.
    /// Automatically overwrites the last `ChatEntity/Role/assistant` message if there is one, otherwise create a new one.
    ///
    /// - Parameters:
    ///     - output: The `ChatEntity/Role/assistant` output `String` (part) that should be appended.
    ///     - overwrite: Indicates if the already present content of the assistant message should be overwritten.
    @MainActor
    public mutating func append(assistantOutput output: String, overwrite: Bool = false) {
        if self.last?.role == .assistant {
            self[self.count - 1] = .init(
                role: .assistant,
                content: overwrite ? output : ((self.last?.content ?? "") + output)
            )
        } else {
            self.append(.init(role: .assistant, content: output))
        }
    }
    
    /// Append an `ChatEntity/Role/user` input to the `Chat`.
    ///
    /// - Parameters:
    ///     - input: The `ChatEntity/Role/user` input that should be appended.
    @MainActor
    public mutating func append(userInput input: String) {
        self.append(.init(role: .user, content: input))
    }
    
    /// Append an `ChatEntity/Role/system` prompt to the `Chat` at the first position.
    ///
    /// - Parameters:
    ///     - systemPrompt: The `ChatEntity/Role/system` prompt of the `Chat`, inserted at the very beginning.
    @MainActor
    public mutating func append(systemMessage systemPrompt: String) {
        self.insert(.init(role: .system, content: systemPrompt), at: 0)
    }
    
    /// Append a `ChatEntity/Role/function` response from a function call to the `Chat.
    ///
    /// - Parameters:
    ///     - functionName: The name of the `ChatEntity/Role/function` that is called by the LLM.
    ///     - functionResponse: The response `String` of the `ChatEntity/Role/function` that is called by the LLM.
    @MainActor
    public mutating func append(forFunction functionName: String, response functionResponse: String) {
        self.append(.init(role: .function(name: functionName), content: functionResponse))
    }
}
