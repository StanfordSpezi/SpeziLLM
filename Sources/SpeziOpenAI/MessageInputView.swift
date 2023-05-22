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
    @State var messageViewHeight: CGFloat = 0
    
    
    public var body: some View {
        HStack(alignment: .bottom) {
            TextField(
                "Ask LLM on FHIR ...",
                text: $message,
                axis: .vertical
            )
                .frame(maxWidth: .infinity) // , minHeight: 32
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(UIColor.systemGray2), lineWidth: 0.2)
                        .background {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.white.opacity(0.2))
                        }
                        .padding(.trailing, -30)
                }
                .lineLimit(1...5)
            Button(
                action: {
                    chat.append(Chat(role: .user, content: message))
                    message = ""
                },
                label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title)
                        .padding(.horizontal, -14)
                        .foregroundColor(
                            message.isEmpty ? Color(.systemGray5) : .accentColor
                        )
                }
            )
                .padding(.trailing, -38)
                .padding(.bottom, 3)
        }
            .padding(.trailing, 23)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(.white.opacity(0.4))
            .background(.thinMaterial)
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            messageViewHeight = proxy.size.height
                        }
                        .onChange(of: message) { _ in
                            messageViewHeight = proxy.size.height
                        }
                }
            }
            .messageInputViewHeight(messageViewHeight)
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
        ZStack {
            Color(.secondarySystemBackground)
                .ignoresSafeArea()
            VStack {
                MessagesView($chat)
                MessageInputView($chat)
            }
                .onPreferenceChange(MessageInputViewHeightKey.self) { newValue in
                    print("New MessageView height: \(newValue)")
                }
        }
    }
}
