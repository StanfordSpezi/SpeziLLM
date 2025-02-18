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


extension LLMOpenAISession {
    /// Initialize the OpenAI OpenAPI client
    ///
    /// - Parameters:
    ///   - continuation: A Swift `AsyncThrowingStream` that streams the generated output.
    /// - Returns: `true` if the client could be initialized, `false` otherwise.
    private func initaliseClient(_ continuation: AsyncThrowingStream<String, any Error>.Continuation) async -> Bool {
        // Overwrite API token if passed
        if let overwritingToken = schema.parameters.overwritingToken {
            do {
                wrappedClient = try Client(
                    serverURL: Servers.Server1.url(),
                    transport: URLSessionTransport(),
                    middlewares: [AuthMiddleware(APIKey: overwritingToken)]
                )
            } catch {
                Self.logger.error("""
                SpeziLLMOpenAI: Couldn't create OpenAI OpenAPI client with the passed API token.
                \(error.localizedDescription)
                """)
                return false
            }
        } else {
            // If token is present within the Spezi `SecureStorage`
            guard let credentials = try? keychainStorage.retrieveCredentials(
                withUsername: LLMOpenAIConstants.credentialsUsername,
                for: .openAIKey
            ) else {
                Self.logger.error("""
                SpeziLLMOpenAI: Missing OpenAI API token.
                Please ensure that the token is either passed directly via the Spezi `Configuration`
                or stored within the `SecureStorage` via the `LLMOpenAITokenSaver` before dispatching the first inference.
                """)
                await finishGenerationWithError(LLMOpenAIError.missingAPIToken, on: continuation)
                return false
            }

            // Initialize the OpenAI model
            do {
                wrappedClient = try Client(
                    serverURL: Servers.Server1.url(),
                    transport: {
                        let session = URLSession.shared
                        session.configuration.timeoutIntervalForRequest = platform.configuration.timeout
                        return URLSessionTransport(configuration: .init(session: session))
                    }(),
                    middlewares: [AuthMiddleware(APIKey: credentials.password)]
                )
            } catch {
                Self.logger.error("""
                LLMOpenAI: Couldn't create OpenAI OpenAPI client with the token present in the Spezi secure storage.
                \(error.localizedDescription)
                """)
                return false
            }
        }
        return true
    }

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
        
        if await !initaliseClient(continuation) {
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
