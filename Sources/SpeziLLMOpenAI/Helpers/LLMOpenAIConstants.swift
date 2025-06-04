//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziKeychainStorage


/// Constants used throughout the `SpeziLLMOpenAI` target.
public enum LLMOpenAIConstants {
    /// Default credentials username of `SpeziLLMOpenAI` .
    public static let credentialsUsername = "OpenAI_Token"
}

/// The credentials tag of the OpenAI API key in the secure enclave.
extension CredentialsTag {
    /// Default `CredentialsTag` of the SpeziLLMOpenAI OpenAI API key.
    public static let openAIKey = CredentialsTag.genericPassword(forService: "openai.com")
}
