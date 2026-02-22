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
    @Environment(KeychainStorage.self) var keychain
    @Environment(LLMOpenAIPlatform.self) var openAIPlatform
    @Environment(LLMOpenAIPlatform.self) var anthropicPlatform
    @Environment(LLMOpenAIPlatform.self) var geminiPlatform
    @AppStorage(StorageKeys.localOnboardingFlowComplete) private var completedLocalOnboardingFlow = false
    @AppStorage(StorageKeys.fogOnboardingFlowComplete) private var completedFogOnboardingFlow = false

    
    func body(content: Content) -> some View {
        content
            .task {
                if FeatureFlags.resetSecureStorage {
                    try? openAIPlatform.clearApiKeyCredentials(in: keychain)
                    try? anthropicPlatform.clearApiKeyCredentials(in: keychain)
                    try? geminiPlatform.clearApiKeyCredentials(in: keychain)
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
