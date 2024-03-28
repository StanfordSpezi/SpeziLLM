//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


enum FeatureFlags: Sendable {
    /// Configures the LLMs to mock all generated responses in order to simplify development and write UI Tests.
    static let mockMode = ProcessInfo.processInfo.arguments.contains("--mockMode")
    /// Resets all credentials in Secure Storage when the application is launched in order to facilitate testing of OpenAI API keys.
    static let resetSecureStorage = ProcessInfo.processInfo.arguments.contains("--resetSecureStorage")
    /// Always show the onboarding when the application is launched. Makes it easy to modify and test the onboarding flow without the need to manually remove the application or reset the simulator.
    static let showOnboarding = ProcessInfo.processInfo.arguments.contains("--showOnboarding")
}
