//
// This source file is part of the SpeziML open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziLocalLLM
import SpeziOpenAI
import SwiftUI

/// Presents a chat view that enables user's to interact with the local LLM.
struct LocalLLMChatView: View {
    /// A `SpeziLLMRunner` responsible for executing the local LLM. Can be configured via the Spezi `Configuration`.
    @EnvironmentObject private var runner: LLMRunner
    /// Represents the chat content that is displayed. Initialized with a default message by the assistant (LLM).
    @State private var chat: [Chat] = [
        .init(role: .assistant, content: "Hello! I'm a locally executed Llama 2 7B model, enabled by the Spezi ecosystem!")
    ]
    
    /// The `SpeziLLMModelLlama` that is configured and executed on the `SpeziLLMRunner`
    private let model: LLMLlama = .init(
        modelPath: LocalLLMDownloadManager.downloadModelLocation,
        parameters: .init(nLength: 64), /// Limits the size of the generated response to 64 tokens
        contextParameters: .init(nCtx: 512) /// Sets the context size of the model at 512 tokens
    )
    
    
    var body: some View {
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
}


#Preview {
    LocalLLMChatView()
}
