//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziKeychainStorage


/// Constants used throughout the `SpeziLLMAnthropic` target.
public enum LLMAnthropicConstants {
    /// Default credentials username of `SpeziLLMAnthropic` .
    public static let credentialsUsername = "Anthropic_Token"
}

/// The credentials tag of the Anthropic API key in the secure enclave.
extension CredentialsTag {
    /// Default `CredentialsTag` of the SpeziLLMAnthropic API key.
    public static let anthropicKey = CredentialsTag.genericPassword(forService: "api.anthropic.com")
}
