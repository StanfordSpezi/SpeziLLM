//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import OpenAI
@_exported import struct OpenAI.Chat
import SwiftUI


/// A view to display an OpenAI-based chat view.
public struct ChatView: View {
    let messagePlaceholder: String?
    
    @Binding var chat: [Chat]
    @Binding var disableInput: Bool
    @State var messageInputHeight: CGFloat = 0
    
    
    public var body: some View {
        ZStack {
            VStack {
                MessagesView($chat, bottomPadding: $messageInputHeight)
                    .gesture(
                        TapGesture().onEnded {
                            UIApplication.shared.sendAction(
                                #selector(
                                    UIResponder.resignFirstResponder
                                ),
                                to: nil,
                                from: nil,
                                for: nil
                            )
                        }
                    )
            }
            VStack {
                Spacer()
                MessageInputView(messagePlaceholder: messagePlaceholder, $chat)
                    .disabled(disableInput)
                    .onPreferenceChange(MessageInputViewHeightKey.self) { newValue in
                        messageInputHeight = newValue
                    }
            }
        }
    }
    
    
    /// - Parameters:
    ///   - chat: The chat that should be displayed.
    ///   - disableInput: Flag if the input view should be disabled.
    public init(
        messagePlaceholder: String? = nil,
        _ chat: Binding<[Chat]>,
        disableInput: Binding<Bool> = .constant(false)
    ) {
        self.messagePlaceholder = messagePlaceholder
        self._chat = chat
        self._disableInput = disableInput
    }
}


struct ChatView_Previews: PreviewProvider {
    @State static var chat = [
        Chat(role: .system, content: "System Message!"),
        Chat(role: .system, content: "System Message (hidden)!"),
        Chat(role: .user, content: "User Message!"),
        Chat(role: .assistant, content: "Assistant Message!")
    ]
    
    
    static var previews: some View {
        ChatView($chat)
    }
}
