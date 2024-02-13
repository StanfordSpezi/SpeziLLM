//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import OpenAI


extension LLMOpenAISession {
    /// Set up the OpenAI LLM execution client.
    ///
    /// - Parameters:
    ///   - continuation: A Swift `AsyncThrowingStream` that streams the generated output.
    /// - Returns: `true` if the setup was successful, `false` otherwise.
    func setup(continuation: AsyncThrowingStream<String, Error>.Continuation) async -> Bool {
        Self.logger.debug("SpeziLLMOpenAI: OpenAI LLM is being initialized")
        await MainActor.run {
            self.state = .loading
        }
        
        // Overwrite API token if passed
        if let overwritingToken = schema.parameters.overwritingToken {
            self.wrappedModel = OpenAI(
                configuration: .init(
                    token: overwritingToken,
                    timeoutInterval: platform.configuration.timeout
                )
            )
        } else {
            // If token is present within the Spezi `SecureStorage`
            guard let credentials = try? secureStorage.retrieveCredentials(
                LLMOpenAIConstants.credentialsUsername,
                server: LLMOpenAIConstants.credentialsServer
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
            self.wrappedModel = OpenAI(
                configuration: .init(
                    token: credentials.password,
                    timeoutInterval: platform.configuration.timeout
                )
            )
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
    private func modelAccessTest(continuation: AsyncThrowingStream<String, Error>.Continuation) async -> Bool {
        do {
            _ = try await self.model.model(query: .init(model: schema.parameters.modelType))
            Self.logger.error("SpeziLLMOpenAI: Model access check completed")
            return true
        } catch let error as URLError {
            Self.logger.error("SpeziLLMOpenAI: Model access check - Connectivity Issues with the OpenAI API: \(error)")
            await finishGenerationWithError(LLMOpenAIError.connectivityIssues(error), on: continuation)
        } catch {
            if let apiError = error as? APIErrorResponse, apiError.error.code == LLMOpenAIError.invalidAPIToken.openAIErrorMessage {
                Self.logger.error("SpeziLLMOpenAI: Model access check - Invalid OpenAI API token: \(apiError)")
                await finishGenerationWithError(LLMOpenAIError.invalidAPIToken, on: continuation)
            } else {
                Self.logger.error("SpeziLLMOpenAI: Model access check - Couldn't access the specified OpenAI model: \(error)")
                await finishGenerationWithError(LLMOpenAIError.modelAccessError(error), on: continuation)
            }
        }
        
        return false
    }
}
