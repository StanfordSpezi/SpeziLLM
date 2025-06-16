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
        
        if !self.initializeClient(continuation) {
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

    /// Initialize the OpenAI OpenAPI client.
    ///
    /// - Parameters:
    ///   - continuation: A Swift `AsyncThrowingStream` that streams the generated output.
    /// - Returns: `true` if the client could be initialized, `false` otherwise.
    private func initializeClient(_ continuation: AsyncThrowingStream<String, any Error>.Continuation) -> Bool {
        let bearerAuthMiddleware = BearerAuthMiddleware(
            authToken: {
                if let overwritingToken = self.schema.parameters.overwritingAuthToken {
                    return overwritingToken
                }

                return self.platform.configuration.authToken
            }(),
            keychainStorage: self.keychainStorage
        )

        // Initialize the OpenAI model
        self.openAiClient = Client(
            serverURL: self.platform.configuration.serverUrl,
            transport: {
                let session = URLSession.shared
                session.configuration.timeoutIntervalForRequest = platform.configuration.timeout
                return URLSessionTransport(configuration: .init(session: session))
            }(),
            middlewares: [
                // Injects the bearer auth token for account verification into request headers
                bearerAuthMiddleware,
                // Retry policy for failed requests
                RetryMiddleware(policy: self.platform.configuration.retryPolicy)
            ]
        )

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
}
