//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import OpenAI
import SwiftUI


/// Displays a textfield to append a message to a chat.
public struct MessageInputView: View {
    @Binding var chat: [Chat]
    @State var message: String = ""
    
    
    public var body: some View {
        HStack {
            TextField(
                "Ask LLM on FHIR ...",
                text: $message,
                axis: .vertical
            )
                .frame(maxWidth: .infinity) // , minHeight: 32
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.secondarySystemBackground), lineWidth: 1)
                        .padding(.trailing, -30)
                )
                .lineLimit(1...5)
            Button(
                action: {
                    chat.append(Chat(role: .user, content: message))
                    message = ""
                },
                label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .padding(.horizontal, -8)
                        .foregroundColor(
                            message.isEmpty ? Color(.systemGray6) : .accentColor
                        )
                }
            )
                .padding(.trailing, -40)
        }
            .padding(.trailing, 23)
    }
    
    
    /// - Parameters:
    ///   - chat: The chat that should be appended to.
    public init(_ chat: Binding<[Chat]>) {
        self._chat = chat
    }
}


struct MessageInputView_Previews: PreviewProvider {
    @State static var chat = [
        Chat(role: .system, content: "System Message!"),
        Chat(role: .system, content: "System Message (hidden)!"),
        Chat(role: .user, content: "User Message!"),
        Chat(role: .assistant, content: "Assistant Message!")
    ]
    
    
    static var previews: some View {
        VStack {
            MessagesView($chat)
            MessageInputView($chat)
        }
    }
}
