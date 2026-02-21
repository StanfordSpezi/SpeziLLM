//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Security
import SpeziKeychainStorage
import SpeziLLMAnthropic
import SpeziLLMGemini
import SpeziLLMOpenAI
import SwiftUI


private struct TestAppTestingSetup: ViewModifier {
    @Environment(KeychainStorage.self) var keychainStorage
    @AppStorage(StorageKeys.localOnboardingFlowComplete) private var completedLocalOnboardingFlow = false
    @AppStorage(StorageKeys.fogOnboardingFlowComplete) private var completedFogOnboardingFlow = false

    
    func body(content: Content) -> some View {
        content
            .task {
                if FeatureFlags.resetSecureStorage {
                    // NOTE: since the corresponding definitions in SpeziLLMOpenAI are internal,
                    // we need to manually ensure that the values here match the values used by SpeziLLM.
                    try? keychainStorage.deleteCredentials(
                        withUsername: LLMOpenAIConstants.credentialsUsername,
                        for: .openAIKey
                    )
                    try? keychainStorage.deleteCredentials(
                        withUsername: LLMAnthropicConstants.credentialsUsername,
                        for: .anthropicKey
                    )
                    try? keychainStorage.deleteCredentials(
                        withUsername: LLMGeminiConstants.credentialsUsername,
                        for: .geminiKey
                    )
                }
                if FeatureFlags.showOnboarding {
                    completedLocalOnboardingFlow = false
                    completedFogOnboardingFlow = false
                }
            }
    }
}


extension View {
    func testingSetup() -> some View {
        self.modifier(TestAppTestingSetup())
    }
}
