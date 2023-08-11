//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Combine
import OpenAI
import SwiftUI


/// Displays the content of a `Chat` message in a message bubble
public struct MessagesView: View {
    private static let bottomSpacerIdentifier = "Bottom Spacer"
    
    @Binding var chat: [Chat]
    @Binding var bottomPadding: CGFloat
    let hideMessagesWithRoles: Set<Chat.Role>
    
    
    private var keyboardPublisher: AnyPublisher<Bool, Never> {
        Publishers
            .Merge(
                NotificationCenter
                    .default
                    .publisher(for: UIResponder.keyboardWillShowNotification)
                    .map { _ in true },
                NotificationCenter
                    .default
                    .publisher(for: UIResponder.keyboardWillHideNotification)
                    .map { _ in false }
            )
            .debounce(for: .seconds(0.1), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    
    public var body: some View {
        ScrollViewReader { scrollViewProxy in
            ScrollView {
                VStack {
                    ForEach(Array(chat.enumerated()), id: \.offset) { _, message in
                        MessageView(message, hideMessageWithRoles: MessageView.Defaults.hideMessagesWithRoles)
                    }
                    Spacer()
                        .frame(height: bottomPadding)
                        .id(MessagesView.bottomSpacerIdentifier)
                }
                    .padding(.horizontal)
                    .onAppear {
                        scrollToBottom(scrollViewProxy)
                    }
                    .onChange(of: chat) { _ in
                        scrollToBottom(scrollViewProxy)
                    }
                    .onReceive(keyboardPublisher) { _ in
                        scrollToBottom(scrollViewProxy)
                    }
            }
        }
    }
    
    
    /// - Parameters:
    ///   - chat: The chat messages that should be displayed.
    ///   - bottomPadding: A fixed bottom padding for the messages view.
    ///   - hideMessagesWithRoles: If .system and/or .function messages should be hidden from view.
    public init(
        _ chat: [Chat],
        bottomPadding: CGFloat = 0,
        hideMessagesWithRoles: Set<Chat.Role>
    ) {
        self._chat = .constant(chat)
        self._bottomPadding = .constant(bottomPadding)
        self.hideMessagesWithRoles = hideMessagesWithRoles
    }

    /// - Parameters:
    ///   - chat: The chat messages that should be displayed.
    ///   - bottomPadding: A fixed bottom padding for the messages view.
    ///   - hideMessagesWithRoles: If .system and/or .function messages should be hidden from view.
    public init(
        _ chat: Binding<[Chat]>,
        bottomPadding: Binding<CGFloat> = .constant(0),
        hideMessagesWithRoles: Set<Chat.Role>
    ) {
        self._chat = chat
        self._bottomPadding = bottomPadding
        self.hideMessagesWithRoles = hideMessagesWithRoles
    }

    
    private func scrollToBottom(_ scrollViewProxy: ScrollViewProxy) {
        withAnimation(.easeOut) {
            scrollViewProxy.scrollTo(MessagesView.bottomSpacerIdentifier)
        }
    }
}


struct MessagesView_Previews: PreviewProvider {
    static var previews: some View {
        MessagesView(
            [
                Chat(role: .system, content: "System Message!"),
                Chat(role: .system, content: "System Message (hidden)!"),
                Chat(role: .function, content: "Function Message!"),
                Chat(role: .user, content: "User Message!"),
                Chat(role: .assistant, content: "Assistant Message!")
            ], hideMessagesWithRoles: MessageView.Defaults.hideMessagesWithRoles
        )
    }
}
