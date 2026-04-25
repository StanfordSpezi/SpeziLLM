//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziChat


extension LLMContext {
    /// Maps the ``LLMContext`` to a `SpeziChat/Chat`.
    @MainActor public var chat: Chat {
        get {
            self.map { contextEntity in     // swiftlint:disable:this closure_body_length
                switch contextEntity.role {
                case .user:
                    ChatEntity(
                        role: .user,
                        content: .text(contextEntity.content),
                        complete: contextEntity.complete,
                        id: contextEntity.id,
                        date: contextEntity.date
                    )
                case .assistant(let toolCalls):
                    if !toolCalls.isEmpty {
                        ChatEntity(
                            role: .assistant(.toolCall),
                            content: .text(toolCalls.map { "\($0.id) \($0.name) \($0.arguments)" }.joined(separator: "\n")),
                            complete: contextEntity.complete,
                            id: contextEntity.id,
                            date: contextEntity.date
                        )
                    } else {
                        ChatEntity(
                            role: .assistant(.response),
                            content: .text(contextEntity.content),
                            complete: contextEntity.complete,
                            id: contextEntity.id,
                            date: contextEntity.date
                        )
                    }
                case .system:
                    ChatEntity(
                        role: .hidden(type: .system),
                        content: .text(contextEntity.content),
                        complete: contextEntity.complete,
                        id: contextEntity.id,
                        date: contextEntity.date
                    )
                case .tool:
                    ChatEntity(
//                        role: .hidden(type: .function),
                        role: .assistant(.toolResponse),
                        content: .text(contextEntity.content),
                        complete: contextEntity.complete,
                        id: contextEntity.id,
                        date: contextEntity.date
                    )
                case .assistantThinking:
                    ChatEntity(
                        role: .assistant(.thinking),
                        content: .text(contextEntity.content),
                        complete: contextEntity.complete,
                        id: contextEntity.id,
                        date: contextEntity.date
                    )
                }
            }
        }
        set {
            // TODO what if:
            // - a message is inserted somewhere in the middle of the chat? (we'd end up duplicating the last message)
            // - the last message is being updated by the client? (we'd end up creating a duplicate new one, instead of updating it)
            /// Write back newly added ``LLMContextEntity/Role-swift.enum/user`` message from `Chat` to the ``LLMSession/context`.
            guard let newEntity = newValue.last,
                  case .user = newEntity.role else {
                return
            }
            switch newEntity.content {
            case .text(let text):
                self.append(userInput: text, id: newEntity.id, date: newEntity.date)
            }
        }
    }
}


extension ChatEntity.HiddenMessageType {
    /// System hidden message type of the `ChatEntity`.
    static let system = ChatEntity.HiddenMessageType(name: "system")
}
