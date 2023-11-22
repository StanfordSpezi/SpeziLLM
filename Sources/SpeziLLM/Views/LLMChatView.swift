//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziChat
import SwiftUI


/// Presents a basic chat view that enables user's to chat with an LLM.
public struct LLMChatView: View {
    /// A ``LLMRunner`` responsible for executing the LLM. Must be configured via the Spezi `Configuration`.
    @Environment(LLMRunner.self) private var runner
    /// Represents the chat content that is displayed.
    @State private var chat: Chat = []
    /// Indicates if the input field is disabled
    @State private var inputDisabled = false
    
    
    /// A SpeziML ``LLM`` that is used for the text generation within the chat view
    private let model: any LLM
    
    
    public var body: some View {
        ChatView($chat, disableInput: $inputDisabled)
            .onChange(of: chat) { oldValue, newValue in
                /// Once the user enters a message in the chat, send a request to the local LLM.
                if oldValue.count != newValue.count,
                   let lastChat = newValue.last, lastChat.role == .user {
                    Task {
                        inputDisabled = true
                        
                        /// Stream the LLMs response via a `AsyncThrowingStream`
                        let stream = try await runner(with: model).generate(prompt: lastChat.content)
                        chat.append(.init(role: .assistant, content: ""))
                        
                        for try await token in stream {
                            let lastMessageContent = chat.last?.content ?? ""
                            chat[chat.count - 1] = .init(role: .assistant, content: lastMessageContent + token)
                        }
                        
                        inputDisabled = false
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
        self._chat = State(wrappedValue: chat)
    }
}


#Preview {
    LLMChatView(
        model: LLMMock(),
        initialSystemPrompt: [.init(role: .assistant, content: "Hello world!")]
    )
}
