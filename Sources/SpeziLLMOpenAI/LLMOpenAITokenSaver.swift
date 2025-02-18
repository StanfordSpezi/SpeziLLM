//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import os
import Spezi
import SpeziKeychainStorage
import SwiftUI

/// Enables to store the OpenAI API key inside the Spezi `KeychainStorage`
///
/// The OpenAI API ``LLMOpenAITokenSaver/token`` is automatically read from / persisted to the  Spezi `KeychainStorage` from an arbitrary SwiftUI `View`.
/// Reading the token from the `KeychainStorage` is automatically done upon module initialization; persistence can be triggered via ``LLMOpenAITokenSaver/store()``.
///
/// If a SwiftUI `Binding` is required (e.g., for a `TextField`), one can bind to the ``LLMOpenAITokenSaver`` via the `@Bindable` property wrapper from SwiftUI.
///
/// One needs to specify the ``LLMOpenAIPlatform`` within the Spezi `Configuration` to be able to access the ``LLMOpenAITokenSaver`` from within the SwiftUI `Environment`.
///
/// ### Usage
///
/// A minimal example using the ``LLMOpenAITokenSaver`` can be seen in the example below. The example includes the Spezi `Configuration` to showcase a complete example.
///
/// ```swift
/// class SpeziConfiguration: SpeziAppDelegate {
///     override var configuration: Configuration {
///         Configuration {
///             LLMRunner {
///                 LLMOpenAIPlatform()
///             }
///         }
///     }
/// }
///
/// struct LLMOpenAIAPITokenOnboardingStep: View {
///     @Environment(LLMOpenAITokenSaver.self) private var tokenSaver
///
///     var body: some View {
///         @Bindable var tokenSaver = tokenSaver
///
///         VStack {
///             TextField("OpenAI API Key", text: $tokenSaver.token)
///
///             Button("Next") {
///                 // Access the collected token
///                 let openAIToken = tokenSaver.token
///                 // ...
///
///                 // Persist the collected token in the keychain
///                 tokenSaver.store()
///             }
///                 .disabled(!tokenSaver.tokenPresent)
///         }
///     }
/// }
/// ```
@Observable
public class LLMOpenAITokenSaver: Module, EnvironmentAccessible, DefaultInitializable {
    static let logger = Logger(subsystem: "edu.stanford.spezi", category: "SpeziLLMOpenAI")
    
    @Dependency(KeychainStorage.self) @ObservationIgnored private var keychainStorage
    
    /// The API token used to interact with the OpenAI API.
    /// Automatically read from the `KeychainStorage` upon `Module` initialization and persisted into the `KeychainStorage` via ``LLMOpenAITokenSaver/store()``
    public var token: String = ""
    
    /// Indicates if a token is present within the Spezi `SecureStorage`.
    public var tokenPresent: Bool {
        self.token.isEmpty ? false : true
    }
    
    
    public required init() {}
    
    
    /// Loads the token from the `SecureStorage` upon initialization of the ``LLMOpenAITokenSaver``.
    public func configure() {
        do {
            guard let token = try keychainStorage.retrieveCredentials(
                withUsername: LLMOpenAIConstants.credentialsUsername,
                for: .openAIKey
            )?.password else {
                return
            }
            
            self.token = token
        } catch {
            Self.logger.critical("""
            SpeziLLMOpenAI: Couldn't read a possibly existing OpenAI API token from the `SecureStorage` (secure enclave).
            Ensure that the used device is able to utilize the secure enclave: \(error)
            """)
        }
    }
    
    /// Stores the token captured by the ``LLMOpenAITokenSaver`` into the `SecureStorage`.
    ///
    /// Upon call, the ``LLMOpenAITokenSaver/token`` is written into the persistent and encrypted `SecureStorage`.
    /// If ``LLMOpenAITokenSaver/token`` is `nil`, the token in the `SecureStorage` will be deleted.
    public func store() {
        do {
            try keychainStorage.store(
                Credentials(username: LLMOpenAIConstants.credentialsUsername, password: token),
                for: .openAIKey
            )
        } catch {
            Self.logger.critical("""
            SpeziLLMOpenAI: Couldn't store the captured OpenAI API token to the `SecureStorage` (secure enclave).
            Ensure that the used device is able to utilize the secure enclave: \(error)
            """)
        }
    }
    
    /// Deletes the token from the `SecureStorage`.
    public func delete() {
        do {
            try keychainStorage.deleteCredentials(withUsername: LLMOpenAIConstants.credentialsUsername, for: .openAIKey)
        } catch {
            Self.logger.critical("""
            SpeziLLMOpenAI: Couldn't delete a possibly existing OpenAI API token from the `SecureStorage` (secure enclave).
            Ensure that the used device is able to utilize the secure enclave: \(error)
            """)
        }
    }
}


extension CredentialsTag {
    static let openAIKey = CredentialsTag.genericPassword(forService: "openai.com")
}
