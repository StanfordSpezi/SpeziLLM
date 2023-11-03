//
// This source file is part of the SpeziML open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziLLM
import SpeziLLMLocal
import SpeziOpenAI
import SwiftUI

/// Presents a chat view that enables user's to interact with the local LLM.
struct LocalLLMChatView: View {
    /// The SpeziML `LLMLlama` that is configured and executed on the `LLMRunner`
    private let model: LLMLlama = .init(
        modelPath: .cachesDirectory.appending(path: "llm.gguf"),    /// Loads the LLM from the passed cache directory
        parameters: .init(nLength: 64), /// Limits the size of the generated response to 64 tokens
        contextParameters: .init(nCtx: 512) /// Sets the context size of the model at 512 tokens
    )
    
    // TODO
    private let model2 = LLMMock()
    
    
    var body: some View {
        LLMChatView(
            model: model2,  // TODO
            initialSystemPrompt: .init(
                role: .assistant,
                content: "Hello! I'm a locally executed Llama 2 7B model, enabled by the Spezi ecosystem!"
            )
        )
    }
}


#Preview {
    LocalLLMChatView()
}
