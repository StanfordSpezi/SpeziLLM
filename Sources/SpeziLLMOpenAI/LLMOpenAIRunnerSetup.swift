//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import OpenAI
import Spezi
import SpeziLLM
import SpeziSecureStorage


/// The ``LLMOpenAIRunnerSetupTask`` sets up the OpenAI environment in order to execute Spezi `LLM`s.
/// The task needs to be stated within the `LLMRunner` initializer in the Spezi `Configuration`.
///
/// One is able to specify Spezi-wide configurations for the OpenAI interaction, such as the API key or a network timeout duration (however, not a requirement!).
/// However, these configurations can be overwritten via individual ``LLMOpenAI`` instances.
///
/// ### Usage
///
/// A minimal example of using the ``LLMOpenAIRunnerSetupTask`` can be found below.
///
/// ```swift
/// class LocalLLMAppDelegate: SpeziAppDelegate {
///     override var configuration: Configuration {
///         Configuration {
///             LLMRunner {
///                 LLMOpenAIRunnerSetupTask(apiToken: "<token123>")
///             }
///         }
///     }
/// }
/// ```
public class LLMOpenAIRunnerSetupTask: LLMRunnerSetupTask {
    static var openAIModel: OpenAI {
        guard let openAIModel = LLMOpenAIRunnerSetupTask.wrappedOpenAIModel else {
            preconditionFailure("""
            Illegal Access: Tried to access the wrapped OpenAI model of the `LLMOpenAIRunnerSetupTask` before being initialized.
            Ensure that the `LLMOpenAIRunnerSetupTask` is passed to the `LLMRunner` within the Spezi `Configuration`.
            """)
        }
        return openAIModel
    }
    private static var wrappedOpenAIModel: OpenAI?
    
    
    @Module.Model private var tokenSaver: LLMOpenAITokenSaver
    @Dependency private var secureStorage: SecureStorage
    
    public let type: LLMHostingType = .cloud
    private let apiToken: String?
    private let timeout: TimeInterval
    
    
    public init(
        apiToken: String? = nil,
        timeout: TimeInterval = 60
    ) {
        self.apiToken = apiToken
        self.timeout = timeout
    }
    
    
    public func configure() {
        self.tokenSaver = LLMOpenAITokenSaver(secureStorage: secureStorage)
    }
    
    public func setupRunner(
        runnerConfig: LLMRunnerConfiguration
    ) async throws {
        // If token passed via init
        if let apiToken {
            LLMOpenAIRunnerSetupTask.wrappedOpenAIModel = OpenAI(
                configuration: .init(
                    token: apiToken,
                    timeoutInterval: self.timeout
                )
            )
            
            try secureStorage.store(
                credentials: Credentials(username: LLMOpenAIConstants.credentialsUsername, password: apiToken),
                server: LLMOpenAIConstants.credentialsServer
            )
        } else {
            // If token is present within the Spezi `SecureStorage`
            guard let credentials = try? secureStorage.retrieveCredentials(
                LLMOpenAIConstants.credentialsUsername,
                server: LLMOpenAIConstants.credentialsServer
            ) else {
                preconditionFailure("""
                SpeziLLM: OpenAI Token wasn't properly set, please ensure that the token is either passed directly via the Spezi `Configuration`
                or stored within the `SecureStorage` via the `LLMOpenAITokenSaver` before dispatching the first inference.
                """)
            }
            
            // Initialize the OpenAI model
            LLMOpenAIRunnerSetupTask.wrappedOpenAIModel = OpenAI(
                configuration: .init(
                    token: credentials.password,
                    timeoutInterval: self.timeout
                )
            )
        }
        
        // Check validity of passed token by making a request to list all models
        do {
            _ = try await LLMOpenAIRunnerSetupTask.openAIModel.models()
        } catch let error as URLError {
            throw LLMOpenAIError.connectivityIssues(error)
        } catch let error as APIErrorResponse {
            if error.error.code == LLMOpenAIError.invalidAPIToken.openAIErrorMessage {
                throw LLMOpenAIError.invalidAPIToken
            }
            throw LLMOpenAIError.unknownError(error)
        } catch {
            throw LLMOpenAIError.unknownError(error)
        }
    }
}
