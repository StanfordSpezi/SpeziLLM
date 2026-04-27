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
            var interactionFirstSeenDates: [LLMInteractionId: Date] = [:]
            var interactionLastSeenDates: [LLMInteractionId: Date] = [:]
            for entity in self {
                guard let id = entity.interactionId else {
                    continue
                }
                if let existing = interactionFirstSeenDates[id] {
                    interactionFirstSeenDates[id] = Swift.min(existing, entity.date)
                } else {
                    interactionFirstSeenDates[id] = entity.date
                }
                if let existing = interactionLastSeenDates[id] {
                    interactionLastSeenDates[id] = Swift.max(existing, entity.date)
                } else {
                    interactionLastSeenDates[id] = entity.date
                }
            }
            // We combine all thinking entities belonging to the same interaction into a single entry,
            // with the first one becomg the anchor, and all subsequent ones being merged into that one.
            var thinkingAnchorIndexByInteraction: [LLMInteractionId: Int] = [:]
            var result: Chat = []
            result.reserveCapacity(self.count)
            for entity in self {
                switch entity.role {
                case .user:
                    result.append(ChatEntity(
                        role: .user,
                        content: .text(entity.content),
                        complete: entity.complete,
                        id: entity.id,
                        date: entity.date
                    ))
                case .assistant:
                    result.append(ChatEntity(
                        role: .assistant(.response),
                        content: .text(entity.content),
                        complete: entity.complete,
                        id: entity.id,
                        date: entity.date
                    ))
                case .toolCalls(let toolCalls):
                    result.append(ChatEntity(
                        role: .assistant(.toolCall),
                        content: .text(toolCalls.map { "\($0.id) \($0.name) \($0.arguments)" }.joined(separator: "\n")),
                        complete: entity.complete,
                        id: entity.id,
                        date: entity.date
                    ))
                case .system:
                    result.append(ChatEntity(
                        role: .hidden(type: .system),
                        content: .text(entity.content),
                        complete: entity.complete,
                        id: entity.id,
                        date: entity.date
                    ))
                case .toolCallResponse:
                    result.append(ChatEntity(
                        role: .assistant(.toolResponse),
                        content: .text(entity.content),
                        complete: entity.complete,
                        id: entity.id,
                        date: entity.date
                    ))
                case .assistantThinking:
                    if let interactionId = entity.interactionId, let anchorIdx = thinkingAnchorIndexByInteraction[interactionId] {
                        // found an entry we can use as anchor. merge the current entry into that one.
                        var anchor = result[anchorIdx]
                        let existingText = switch anchor.content {
                        case .text(let text): text
                        }
                        let mergedText: String
                        if existingText.isEmpty {
                            mergedText = entity.content
                        } else if entity.content.isEmpty {
                            mergedText = existingText
                        } else {
                            mergedText = existingText + "\n\n" + entity.content
                        }
                        anchor.role = .assistant(.thinking(
                            startDate: interactionFirstSeenDates[interactionId],
                            endDate: interactionLastSeenDates[interactionId]
                        ))
                        anchor.content = .text(mergedText)
                        // only mark as complete once all entities are completed.
                        anchor.complete = anchor.complete && entity.complete
                        result[anchorIdx] = anchor
                    } else {
                        // no matching anchor found
                        if let interactionId = entity.interactionId {
                            thinkingAnchorIndexByInteraction[interactionId] = result.count
                        }
                        result.append(ChatEntity(
                            role: .assistant(.thinking(
                                startDate: entity.interactionId.flatMap { interactionFirstSeenDates[$0] },
                                endDate: entity.interactionId.flatMap { interactionLastSeenDates[$0] }
                            )),
                            content: .text(entity.content),
                            complete: entity.complete,
                            id: entity.id,
                            date: entity.date
                        ))
                    }
                }
            }
            return result
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
