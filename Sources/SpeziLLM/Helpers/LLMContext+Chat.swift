//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziChat


extension LLMContext {
    /// Maps the ``LLMContext`` to a `SpeziChat/Chat`.
    public var chat: Chat {
        get {
            var interactionStartDates: [LLMInteractionId: Date] = [:]
            return self.map { entity in // swiftlint:disable:this closure_body_length
                if let interactionId = entity.interactionId, interactionStartDates[interactionId] == nil {
                    interactionStartDates[interactionId] = entity.date
                }
                return switch entity.role {
                case .user:
                    ChatEntity(
                        role: .user,
                        content: .text(entity.content),
                        complete: entity.complete,
                        id: entity.id,
                        date: entity.date
                    )
                case .assistant:
                    ChatEntity(
                        role: .assistant(.response),
                        content: .text(entity.content),
                        complete: entity.complete,
                        id: entity.id,
                        date: entity.date
                    )
                case .toolCalls(let toolCalls):
                    ChatEntity(
                        role: .assistant(.toolCall),
                        content: .text(toolCalls.map { "\($0.id) \($0.name) \($0.arguments)" }.joined(separator: "\n")),
                        complete: entity.complete,
                        id: entity.id,
                        date: entity.date
                    )
                case .system:
                    ChatEntity(
                        role: .hidden(type: .system),
                        content: .text(entity.content),
                        complete: entity.complete,
                        id: entity.id,
                        date: entity.date
                    )
                case .toolCallResponse:
                    ChatEntity(
                        role: .assistant(.toolResponse),
                        content: .text(entity.content),
                        complete: entity.complete,
                        id: entity.id,
                        date: entity.date
                    )
                case .assistantThinking:
                    ChatEntity(
                        role: .assistant(.thinking(
                            startDate: entity.interactionId.flatMap { interactionStartDates[$0] }
                        )),
                        content: .text(entity.content),
                        complete: entity.complete,
                        id: entity.id,
                        date: entity.date
                    )
                }
            }
        }
        set {
            // QUESTION what if:
            // - a message is inserted somewhere in the middle of the chat? (we'd end up duplicating the last message)
            // - the last message is being updated by the client? (we'd end up creating a duplicate new one, instead of updating it)
            /// Write back newly added ``LLMContextEntity/Role-swift.enum/user`` message from `Chat` to the ``LLMSession/context`.
            guard let newEntity = newValue.last,
                  case .user = newEntity.role else {
                return
            }
            switch newEntity.content {
            case .text(let text):
                self.append(userMessage: text, id: newEntity.id, date: newEntity.date)
            }
        }
    }
}


extension ChatEntity.HiddenMessageType {
    /// System hidden message type of the `ChatEntity`.
    static let system = ChatEntity.HiddenMessageType(name: "system")
}
