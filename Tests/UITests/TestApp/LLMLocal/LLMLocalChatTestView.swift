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
    private var model: LLM = {
        if FeatureFlags.mockMode {
            LLMMock()
        } else {
            LLMLocal(
                modelPath: .cachesDirectory.appending(path: "llm.gguf"),    /// Loads the LLM from the passed cache directory
                parameters: .init(maxOutputLength: 512), /// Limits the size of the generated response to 512 tokens
                contextParameters: .init(contextWindowSize: 1024) /// Sets the context size of the model at 1024 tokens
            )
        }
    }()
    
    
    var body: some View {
        LLMChatView(
            model: model
        )
            .navigationTitle("LLM_LOCAL_CHAT_VIEW_TITLE")
    }
}


#Preview {
    LLMLocalChatTestView()
}
