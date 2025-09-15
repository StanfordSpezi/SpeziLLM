//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

/// Constants shared across the LLM execution demo application to access storage information including the `AppStorage`.
enum StorageKeys {
    /// A `Bool` flag indicating of the local onboarding was completed.
    static let localOnboardingFlowComplete = "localOnboardingFlow.complete"
    /// A `Bool` flag indicating of the fog onboarding was completed.
    static let fogOnboardingFlowComplete = "fogOnboardingFlow.complete"
}
