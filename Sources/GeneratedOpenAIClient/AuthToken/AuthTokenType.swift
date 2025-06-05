//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziKeychainStorage


/// The type of auth token for remote LLM services, such as the OpenAI or Fog layer.
public enum RemoteLLMInferenceAuthToken: Sendable {
    /// No auth token.
    case none
    /// Constant auth token that is static during the lifetime of the ``RemoteLLMInferenceAuthToken``.
    case constant(String)
    /// Auth token persisted in the keychain tagged with the `CredentialsTag` and username, dynamically read from the keychain upon every request.
    case keychain(tag: CredentialsTag, username: String)
    /// Auth token dynamically produced by a closure, reevaluated upon every request.
    case closure(@Sendable () async -> String?)
}
