//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziKeychainStorage


/// The type of auth token, either a constant one or a dynamically generated one via a closure.
public enum RemoteLLMInferenceAuthToken: Sendable {
    /// No auth token
    case none
    /// Content auth token that is hardcoded
    case constant(String)
    /// Auth token is derived from user input and stored in keychain
    case keychain(CredentialsTag)
    /// Dynamic auth token produced by closure.
    case closure(@Sendable () async -> String?)
}
