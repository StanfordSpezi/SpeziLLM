//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziLLM
import SpeziLLMLocal
import SwiftUI


/// Presents a chat view that enables user's to interact with the local LLM.
struct LLMLocalChatTestView: View {
    /// The Spezi `LLM` that is configured and executed on the `LLMRunner`
    private let model: LLM = {
        if FeatureFlags.mockLocalLLM {
            LLMMock()
        } else {
            LLMLlama(
                modelPath: .cachesDirectory.appending(path: "llm.gguf"),    /// Loads the LLM from the passed cache directory
                parameters: .init(maxOutputLength: 64), /// Limits the size of the generated response to 64 tokens
                contextParameters: .init(contextWindowSize: 512) /// Sets the context size of the model at 512 tokens
            )
        }
    }()
    
    
    var body: some View {
        LLMChatView(
            model: model,
            initialSystemPrompt: [
                .init(
                    role: .assistant,
                    content: "Hello! I'm a locally executed Llama 2 7B model, enabled by the Spezi ecosystem!"
                )
            ]
        )
            .navigationTitle("LLM_LOCAL_CHAT_VIEW_TITLE")
    }
}


#Preview {
    LLMLocalChatTestView()
}
