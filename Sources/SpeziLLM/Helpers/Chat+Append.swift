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
    @MainActor
    public mutating func append(assistantOutput output: String) {
        if self.last?.role == .assistant {
            self[self.count - 1] = .init(
                role: self.last?.role ?? .assistant,
                content: (self.last?.content ?? "") + output
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
}
