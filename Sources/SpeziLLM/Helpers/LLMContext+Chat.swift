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
                        content: contextEntity.content,
                        complete: contextEntity.complete,
                        id: contextEntity.id,
                        date: contextEntity.date
                    )
                case .assistant(let toolCalls):
                    if !toolCalls.isEmpty {
                        ChatEntity(
                            role: .hidden(type: .assistantToolCall),
                            content: toolCalls.map { "\($0.id) \($0.name) \($0.arguments)" }.joined(separator: "\n"),
                            complete: contextEntity.complete,
                            id: contextEntity.id,
                            date: contextEntity.date
                        )
                    } else {
                        ChatEntity(
                            role: .assistant,
                            content: contextEntity.content,
                            complete: contextEntity.complete,
                            id: contextEntity.id,
                            date: contextEntity.date
                        )
                    }
                case .system:
                    ChatEntity(
                        role: .hidden(type: .system),
                        content: contextEntity.content,
                        complete: contextEntity.complete,
                        id: contextEntity.id,
                        date: contextEntity.date
                    )
                case .tool:
                    ChatEntity(
                        role: .hidden(type: .function),
                        content: contextEntity.content,
                        complete: contextEntity.complete,
                        id: contextEntity.id,
                        date: contextEntity.date
                    )
                }
            }
        }
        set {
            /// Write back newly added ``LLMContextEntity/Role-swift.enum/user`` message from `Chat` to the ``LLMSession/context`.
            guard let newEntity = newValue.last,
                  case .user = newEntity.role else {
                return
            }
            
            self.append(userInput: newEntity.content, id: newEntity.id, date: newEntity.date)
        }
    }
}


extension ChatEntity.HiddenMessageType {
    /// Assistant tool call hidden message type of the `ChatEntity`.
    static let assistantToolCall = ChatEntity.HiddenMessageType(name: "assistantToolCall")
    /// System hidden message type of the `ChatEntity`.
    static let system = ChatEntity.HiddenMessageType(name: "system")
    /// Function hidden message type of the `ChatEntity`.
    static let function = ChatEntity.HiddenMessageType(name: "function")
}
