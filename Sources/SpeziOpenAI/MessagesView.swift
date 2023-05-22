//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import OpenAI
import SwiftUI


/// Displays the content of a `Chat` message in a message bubble
public struct MessagesView: View {
    @Binding var chat: [Chat]
    let hideSystemMessages: Bool
    
    
    public var body: some View {
        ScrollView {
            VStack {
                ForEach(Array(chat.enumerated()), id: \.offset) { _, message in
                    MessageView(message)
                }
            }
        }
    }
    
    
    /// - Parameters:
    ///   - chat: The chat messages that should be displayed.
    ///   - hideSystemMessages: If system messages should be hidden from the chat overview.
    public init(_ chat: [Chat], hideSystemMessages: Bool = true) {
        self._chat = .constant(chat)
        self.hideSystemMessages = hideSystemMessages
    }
    
    
    /// - Parameters:
    ///   - chat: The chat messages that should be displayed.
    ///   - hideSystemMessages: If system messages should be hidden from the chat overview.
    public init(_ chat: Binding<[Chat]>, hideSystemMessages: Bool = true) {
        self._chat = chat
        self.hideSystemMessages = hideSystemMessages
    }
}


struct MessagesView_Previews: PreviewProvider {
    static var previews: some View {
        MessagesView(
            [
                Chat(role: .system, content: "System Message!"),
                Chat(role: .system, content: "System Message (hidden)!"),
                Chat(role: .user, content: "User Message!"),
                Chat(role: .assistant, content: "Assistant Message!")
            ]
        )
            .padding()
    }
}
