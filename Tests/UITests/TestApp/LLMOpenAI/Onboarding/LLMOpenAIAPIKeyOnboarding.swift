//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziLLMOpenAI
import SpeziViews
import SwiftUI


/// Onboarding view for setting a static API key for use with an OpenAI-like API.
///
/// - Important: Only use this view if the auth token on the `LLMOpenAIPlatform` is set to `RemoteLLMInferenceAuthToken/keychain(_:CredentialsTag)`.
struct LLMOpenAILikeAPIKeyOnboarding<PlatformConfig: LLMOpenAILikePlatformConfiguration>: View {
    @Environment(ManagedNavigationStack.Path.self) private var path
    #if os(visionOS)
    @Environment(\.dismiss) private var dismiss
    #endif

    
    var body: some View {
        LLMOpenAILikeAPITokenOnboardingStep<PlatformConfig> {
            path.nextStep()
        }
            #if os(visionOS)
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

#if DEBUG
#Preview {
    ManagedNavigationStack {
        LLMOpenAILikeAPIKeyOnboarding<LLMOpenAIPlatformConfiguration>()
    }
        .previewWith {
            LLMOpenAIPlatform(
                configuration: .init(
                    authToken: .keychain(tag: .openAIKey, username: LLMOpenAIConstants.credentialsUsername)
                )
            )
        }
}
#endif
