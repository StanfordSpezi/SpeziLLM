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
public struct MessageView: View {
    public enum Defaults {
        public static let hideMessagesWithRoles: Set<Chat.Role> = [.system, .function]
    }
    
    
    private let chat: Chat
    private let hideMessagesWithRoles: Set<Chat.Role>

    
    private var foregroundColor: Color {
        chat.allignment == .leading ? .primary : .white
    }
    
    private var backgroundColor: Color {
        chat.allignment == .leading ? Color(.secondarySystemBackground) : .accentColor
    }
    
    private var multilineTextAllignment: TextAlignment {
        chat.allignment == .leading ? .leading : .trailing
    }
    
    private var arrowRotation: Angle {
        .degrees(chat.allignment == .leading ? -50 : -130)
    }
    
    private var arrowAllignment: CGFloat {
        chat.allignment == .leading ? -7 : 7
    }
    
    public var body: some View {
        if !hideMessagesWithRoles.contains(chat.role), let content = chat.content {
            HStack {
                if chat.allignment == .trailing {
                    Spacer(minLength: 32)
                }
                Text(content)
                    .multilineTextAlignment(multilineTextAllignment)
                    .frame(idealWidth: .infinity)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .foregroundColor(foregroundColor)
                    .background(backgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        Image(systemName: "arrowtriangle.left.fill")
                            .foregroundColor(backgroundColor)
                            .rotationEffect(arrowRotation)
                            .offset(x: arrowAllignment),
                        alignment: chat.allignment == .leading ? .bottomLeading : .bottomTrailing
                    )
                    .padding(.horizontal, 4)
                if chat.allignment == .leading {
                    Spacer(minLength: 32)
                }
            }
        }
    }
    
    
    /// - Parameters:
    ///   - chat: The chat message that should be displayed.
    ///   - hideMessagesWithRoles: If .system and/or .function messages should be hidden from the chat overview.
    public init(_ chat: Chat, hideMessagesWithRoles: Set<Chat.Role> = MessageView.Defaults.hideMessagesWithRoles) {
        self.chat = chat
        self.hideMessagesWithRoles = hideMessagesWithRoles
    }
}


struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack {
                MessageView(Chat(role: .system, content: "System Message!"), hideMessagesWithRoles: [])
                MessageView(Chat(role: .system, content: "System Message (hidden)!"))
                MessageView(Chat(role: .function, content: "Function Message!"), hideMessagesWithRoles: [.system])
                MessageView(Chat(role: .user, content: "User Message!"))
                MessageView(Chat(role: .assistant, content: "Assistant Message!"))
            }
            .padding()
        }
    }
}
