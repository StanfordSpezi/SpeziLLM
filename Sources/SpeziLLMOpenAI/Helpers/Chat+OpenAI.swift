//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziChat
import struct OpenAI.Chat


extension SpeziChat.ChatEntity.Role {
    /// Maps the `SpeziChat/ChatEntity/Role`s to the `OpenAI/Chat/Role`s.
    var openAIRepresentation: OpenAI.Chat.Role {
        switch self {
        case .assistant: .assistant
        case .user: .user
        case .system: .system
        case .function: .function
        }
    }
}
