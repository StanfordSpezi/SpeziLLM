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

struct LocalLLMChatView: View {
    @EnvironmentObject var runner: SpeziLLMRunner
    @State var chat: [Chat] = [
        .init(role: .assistant, content: "Hello! I'm a locally executed Llama 2 7B model, enabled by the Spezi ecosystem!")
    ]
    
    let model: SpeziLLMModelLlama = .init(
        modelPath: .applicationDirectory.appending(path: "llm.gguf"),
        modelParameters: .init(nLength: 64, addBos: false),
        contextParameters: .init(nCtx: 512)
    )
    
    
    var body: some View {
        ChatView($chat)
            .navigationTitle("Spezi Local LLM Chat")
            .onChange(of: chat) { oldValue, newValue in
                if oldValue.count != newValue.count,
                   let lastChat = newValue.last, lastChat.role == .user,
                   let userChatContent = lastChat.content {
                    Task {
                        let stream = try await runner(with: model).generate(prompt: userChatContent)
                        chat.append(Chat(role: .assistant, content: ""))
                        var newContent = ""
                        
                        for try await token in stream {
                            let lastMessageContent = chat.last?.content ?? ""
                            chat[chat.count - 1] = Chat(role: .assistant, content: lastMessageContent + token)
                            newContent.append(token)
                        }
                    }
                }
            }
    }
}


#Preview {
    LocalLLMChatView()
}
