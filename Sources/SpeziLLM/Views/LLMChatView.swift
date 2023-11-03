//
// This source file is part of the SpeziML open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziOpenAI
import SwiftUI


/// Presents a basic chat view that enables user's to chat with an LLM.
public struct LLMChatView: View {
    /// A ``LLMRunner`` responsible for executing the LLM. Must be configured via the Spezi `Configuration`.
    @EnvironmentObject private var runner: LLMRunner
    /// Represents the chat content that is displayed.
    @State private var chat: [Chat] = []
    
    /// A SpeziML ``LLM`` that is used for the text generation within the chat view
    private let model: any LLM
    
    
    public var body: some View {
        ChatView($chat)
            .navigationTitle("CHAT_VIEW_TITLE")
            .onChange(of: chat) { oldValue, newValue in
                /// Once the user enters a message in the chat, send a request to the local LLM.
                if oldValue.count != newValue.count,
                   let lastChat = newValue.last, lastChat.role == .user,
                   let userChatContent = lastChat.content {
                    Task {
                        /// Stream the LLMs response via a `AsyncThrowingStream`
                        let stream = try await runner(with: model).generate(prompt: userChatContent)
                        chat.append(Chat(role: .assistant, content: ""))
                        
                        for try await token in stream {
                            let lastMessageContent = chat.last?.content ?? ""
                            chat[chat.count - 1] = Chat(role: .assistant, content: lastMessageContent + token)
                        }
                    }
                }
            }
    }
    
    
    /// Creates a ``LLMChatView`` that provides developers with a basic chat view towards a SpeziML ``LLM``.
    ///
    /// - Parameters:
    ///   - model: The SpeziML ``LLM`` that should be used for the text generation.
    ///   - initialSystemPrompt: The initial prompt by the system.
    public init(
        model: any LLM,
        initialSystemPrompt chat: Chat
    ) {
        self.model = model
        self.chat = [chat]
    }
}


#Preview {
    LLMChatView(
        model: LLMMock(),
        initialSystemPrompt: .init(role: .assistant, content: "Hello world!")
    )
}
