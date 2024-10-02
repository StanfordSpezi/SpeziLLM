//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

extension LLMOpenAISession {
    /// Initialize the OpenAI OpenAPI client
    ///
    /// - Parameters:
    ///   - continuation: A Swift `AsyncThrowingStream` that streams the generated output.
    /// - Returns: `true` if the client could be initialized, `false` otherwise.
    private func initaliseClient(_ continuation: AsyncThrowingStream<String, Error>.Continuation) async -> Bool {
        // Overwrite API token if passed
        if let overwritingToken = schema.parameters.overwritingToken {
            do {
                wrappedClient = try Client(
                    serverURL: Servers.server1(),
                    transport: URLSessionTransport(),
                    middlewares: [AuthMiddleware(APIKey: overwritingToken)]
                )
            } catch {
                logger.error("""
                SpeziLLMOpenAI: Couldn't create OpenAI OpenAPI client with the passed API token.
                \(error.localizedDescription)
                """)
                return false
            }
        } else {
            // If token is present within the Spezi `SecureStorage`
            guard let credentials = try? secureStorage.retrieveCredentials(
                LLMOpenAIConstants.credentialsUsername,
                server: LLMOpenAIConstants.credentialsServer
            ) else {
                logger.error("""
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
                    serverURL: Servers.server1(),
                    transport: URLSessionTransport(),
                    middlewares: [AuthMiddleware(APIKey: credentials.password)]
                )
            } catch {
                logger.error("""
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
    func setup(continuation: AsyncThrowingStream<String, Error>.Continuation) async -> Bool {
        logger.debug("SpeziLLMOpenAI: OpenAI LLM is being initialized")
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
        logger.debug("SpeziLLMOpenAI: OpenAI LLM finished initializing, now ready to use")
        return true
    }
    
    /// Tests access to the OpenAI model.
    ///
    /// - Parameters:
    ///   - continuation: A Swift `AsyncThrowingStream` that streams the generated output.
    /// - Returns: `true` if the model access test was successful, `false` otherwise.
    private func modelAccessTest(continuation: AsyncThrowingStream<String, Error>.Continuation) async -> Bool {
        do {
            guard let modelVal = schema.parameters.modelType.value2?.rawValue else {
                logger.error("No modelType present.")
                return false
            }
            if case let .undocumented(statusCode, _) = try await chatGPTClient
                .retrieveModel(.init(path: .init(model: modelVal))) {
                logger.error("SpeziLLMOpenAI: Error in model access check. Status code: \(statusCode)")
                return false
            }
            logger.error("SpeziLLMOpenAI: Model access check completed")
            return true
        } catch let error as URLError {
            logger.error("SpeziLLMOpenAI: Model access check - Connectivity Issues with the OpenAI API: \(error)")
            await finishGenerationWithError(LLMOpenAIError.connectivityIssues(error), on: continuation)
        } catch {
            logger.error("SpeziLLMOpenAI: Model access check - unknown error occurred")
        }
        return false
    }
}
