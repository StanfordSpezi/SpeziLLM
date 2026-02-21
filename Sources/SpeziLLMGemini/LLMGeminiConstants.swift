//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziKeychainStorage


/// Constants used throughout the `SpeziLLMGemini` target.
public enum LLMGeminiConstants {
    /// Default credentials username of `SpeziLLMGemini` .
    public static let credentialsUsername = "Gemini_Token"
}

/// The credentials tag of the Gemini API key in the secure enclave.
extension CredentialsTag {
    /// Default `CredentialsTag` of the SpeziLLMGemini API key.
    public static let geminiKey = CredentialsTag.genericPassword(forService: "generativelanguage.googleapis.com")
}
