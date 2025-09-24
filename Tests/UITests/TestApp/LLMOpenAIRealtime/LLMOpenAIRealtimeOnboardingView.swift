//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziLLMOpenAIRealtime
import SpeziViews
import SwiftUI


struct LLMOpenAIRealtimeOnboardingView: View {
    #if os(macOS)
    @Environment(\.dismiss) private var dismiss
    #endif
    @Binding var session: LLMOpenAIRealtimeSession


    var body: some View {
        ManagedNavigationStack {
            LLMOpenAIRealtimeTokenOnboarding(session: $session)
        }
            #if os(macOS)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .accessibilityLabel(Text("DISMISS_BUTTON_LABEL"))
                    }
                }
            }
            #endif
    }
}
