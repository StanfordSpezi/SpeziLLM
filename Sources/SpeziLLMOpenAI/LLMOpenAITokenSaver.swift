//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziSecureStorage
import SwiftUI

/// Enables to store the OpenAI API key (token) inside the Spezi `SecureStorage` (secure enclave) from an arbitrary `View`.
/// The ``LLMOpenAITokenSaver`` provides the ``LLMOpenAITokenSaver/token`` property to easily read and write to the `SecureStorage`.
/// If a SwiftUI `Binding` is required (e.g., for a `TextField`), one can use the ``LLMOpenAITokenSaver/tokenBinding`` property.
///
/// One needs to specify the ``LLMOpenAIRunnerSetupTask`` within the Spezi `Configuration` to be able to access the ``LLMOpenAITokenSaver`` from within the SwiftUI `Environment`.
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
///                 LLMOpenAIRunnerSetupTask()
///             }
///         }
///     }
/// }
///
/// struct LLMOpenAIAPITokenOnboardingStep: View {
///     @Environment(LLMOpenAITokenSaver.self) private var tokenSaver
///
///     var body: some View {
///         VStack {
///             TextField("OpenAI API Key", text: tokenSaver.tokenBinding)
///
///             Button("Next") {
///                 let openAIToken = tokenSaver.token
///                 // ...
///             }
///                 .disabled(!tokenSaver.tokenPresent)
///         }
///     }
/// }
/// ```
@Observable
public class LLMOpenAITokenSaver {
    private let secureStorage: SecureStorage
    
    
    /// Indicates if a token is present within the Spezi `SecureStorage`.
    public var tokenPresent: Bool {
        self.token == nil ? false : true
    }
    
    /// The API token used to interact with the OpenAI API.
    /// Every write to this property is automatically persisted in the Spezi `SecureStorage`, reads are also done directly from the Spezi `SecureStorage`.
    public var token: String? {
        get {
            access(keyPath: \.token)
            return try? secureStorage.retrieveCredentials(LLMOpenAIConstants.credentialsUsername, server: LLMOpenAIConstants.credentialsServer)?.password
        }
        set {
            withMutation(keyPath: \.token) {
                if let newValue {
                    try? secureStorage.store(
                        credentials: Credentials(username: LLMOpenAIConstants.credentialsUsername, password: newValue),
                        server: LLMOpenAIConstants.credentialsServer
                    )
                } else {
                    try? secureStorage.deleteCredentials(LLMOpenAIConstants.credentialsUsername, server: LLMOpenAIConstants.credentialsServer)
                }
            }
        }
    }
    
    /// Provides SwiftUI `Binding` access to the ``LLMOpenAITokenSaver/token`` property. Useful for, e.g., `TextField`s.
    /// Similar to ``LLMOpenAITokenSaver/token``, all reads / writes are directly done from / to storage.
    public var tokenBinding: Binding<String> {
        Binding(
            get: {
                self.token ?? ""
            },
            set: { newValue in
                guard !newValue.isEmpty else {
                    self.token = nil
                    return
                }
                
                self.token = newValue
            }
        )
    }
    
    
    init(secureStorage: SecureStorage) {
        self.secureStorage = secureStorage
    }
}
