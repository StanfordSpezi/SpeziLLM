//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import GeneratedOpenAIClient
import OpenAPIRuntime
import OpenAPIURLSession
import SpeziKeychainStorage


extension LLMOpenAISession {
    /// Set up the OpenAI LLM execution client.
    ///
    /// - Parameters:
    ///   - continuation: A Swift `AsyncThrowingStream` that streams the generated output.
    /// - Returns: `true` if the setup was successful, `false` otherwise.
    func setup(continuation: AsyncThrowingStream<String, any Error>.Continuation) async -> Bool {
        Self.logger.debug("SpeziLLMOpenAI: OpenAI LLM is being initialized")
        await MainActor.run {
            self.state = .loading
        }
        
        if await !self.initializeClient(continuation) {
            return false
        }

        // Check access to the specified OpenAI model
        if schema.parameters.modelAccessTest,
           await !modelAccessTest(continuation: continuation) {
            return false
        }
        
        await MainActor.run {
            self.state = .ready
        }
        Self.logger.debug("SpeziLLMOpenAI: OpenAI LLM finished initializing, now ready to use")
        return true
    }

    /// Initialize the OpenAI OpenAPI client
    ///
    /// - Parameters:
    ///   - continuation: A Swift `AsyncThrowingStream` that streams the generated output.
    /// - Returns: `true` if the client could be initialized, `false` otherwise.
    private func initializeClient(_ continuation: AsyncThrowingStream<String, any Error>.Continuation) async -> Bool {
        // Overwrite API token if passed
        if let overwritingAuthToken = self.schema.parameters.overwritingAuthToken {
            guard let bearerAuthMiddleware = self.buildBearerAuthMiddleware(authToken: overwritingAuthToken) else {
                // todo: fix text and error desc
                Self.logger.error("""
                SpeziLLMOpenAI: Missing OpenAI API token.
                Please ensure that the token is either passed directly via the Spezi `Configuration`
                or stored within the `SecureStorage` via the `LLMOpenAITokenSaver` before dispatching the first inference.
                """)
                await finishGenerationWithError(LLMOpenAIError.missingAPITokenInKeychain, on: continuation)
                return false
            }

            self.wrappedClient = Client(
                serverURL: self.platform.configuration.serverUrl,
                transport: URLSessionTransport(),
                middlewares: [
                    bearerAuthMiddleware,
                    RetryMiddleware(policy: self.platform.configuration.retryPolicy)
                ]
            )
        } else {
            guard let bearerAuthMiddleware = self.buildBearerAuthMiddleware(authToken: self.platform.configuration.authToken) else {
                // todo: fix text and error desc
                Self.logger.error("""
                SpeziLLMOpenAI: Missing OpenAI API token.
                Please ensure that the token is either passed directly via the Spezi `Configuration`
                or stored within the `SecureStorage` via the `LLMOpenAITokenSaver` before dispatching the first inference.
                """)
                await finishGenerationWithError(LLMOpenAIError.missingAPITokenInKeychain, on: continuation)
                return false
            }

            // Initialize the OpenAI model
            self.wrappedClient = Client(
                serverURL: self.platform.configuration.serverUrl,
                transport: {
                    let session = URLSession.shared
                    session.configuration.timeoutIntervalForRequest = platform.configuration.timeout
                    return URLSessionTransport(configuration: .init(session: session))
                }(),
                middlewares: [
                    bearerAuthMiddleware,
                    RetryMiddleware(policy: self.platform.configuration.retryPolicy)
                ]
            )
        }

        return true
    }

    /// Tests access to the OpenAI model.
    ///
    /// - Parameters:
    ///   - continuation: A Swift `AsyncThrowingStream` that streams the generated output.
    /// - Returns: `true` if the model access test was successful, `false` otherwise.
    private func modelAccessTest(continuation: AsyncThrowingStream<String, any Error>.Continuation) async -> Bool {
        do {
            if case let .undocumented(statusCode, _) = try await openAiClient
                .retrieveModel(.init(path: .init(model: schema.parameters.modelType))) {
                let llmError = handleErrorCode(statusCode)
                await finishGenerationWithError(llmError, on: continuation)
                return false
            }
            Self.logger.debug("SpeziLLMOpenAI: Model access check completed")
            return true
        } catch let error as ClientError {
            Self.logger.error("SpeziLLMOpenAI: Model access check - Connectivity Issues with the OpenAI API: \(error)")
            await finishGenerationWithError(LLMOpenAIError.connectivityIssues(error), on: continuation)
        } catch {
            Self.logger.error("SpeziLLMOpenAI: Model access check - unknown error occurred")
            await finishGenerationWithError(LLMOpenAIError.generationError, on: continuation)
        }
        return false
    }

    private func buildBearerAuthMiddleware(authToken: RemoteLLMInferenceAuthToken) -> BearerAuthMiddleware? {
        // Extract token from keychain if specified
        if case .keychain(let credential) = authToken {
            let credential = try? keychainStorage.retrieveCredentials(
                withUsername: LLMOpenAIConstants.credentialsUsername,
                for: credential
            )

            return try? .init(authToken: authToken, keychainToken: credential?.password)
        } else {
            return try? .init(authToken: authToken, keychainToken: nil)
        }
    }
}
