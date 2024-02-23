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
    let mockMode: Bool
    
    
    var body: some View {
        Group {
            if FeatureFlags.mockMode || mockMode {
                LLMChatViewSchema(
                    with: LLMMockSchema()
                )
            } else {
                LLMChatViewSchema(
                    with: LLMLocalSchema(
                        modelPath: .cachesDirectory.appending(path: "llm.gguf"),
                        parameters: .init(maxOutputLength: 512),
                        contextParameters: .init(contextWindowSize: 1024),
                        formatChat: LLMLocalSchema.PromptFormattingDefaults.llama2
                    )
                )
            }
        }
            .navigationTitle("LLM_LOCAL_CHAT_VIEW_TITLE")
    }
                                         
                                         
    init(mockMode: Bool = false) {
        self.mockMode = mockMode
    }
}


#if DEBUG
#Preview {
    NavigationStack {
        LLMLocalChatTestView(mockMode: true)
    }
        .previewWith {
            LLMRunner {
                LLMMockPlatform()
            }
        }
}
#endif
