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
                preconditionFailure("""
                SpeziLLM: OpenAI Token wasn't properly set, please ensure that the token is either passed directly via the Spezi `Configuration`
                or stored within the `SecureStorage` via the `LLMOpenAITokenSaver` before dispatching the first inference.
                """)
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
        if schema.parameters.modelAccessTest {
            do {
                _ = try await self.model.model(query: .init(model: schema.parameters.modelType))
            } catch let error as URLError {
                Self.logger.error("SpeziLLMOpenAI: Connectivity Issues with the OpenAI API - \(error)")
                await finishGenerationWithError(LLMOpenAIError.connectivityIssues(error), on: continuation)
                return false
            } catch {
                LLMOpenAI.logger.error("""
                SpeziLLMOpenAI: Couldn't access the specified OpenAI model.
                Ensure the model exists and the configured API key is able to access the model.
                Error: \(error)
                """)
                await finishGenerationWithError(LLMOpenAIError.modelAccessError(error), on: continuation)
                return false
            }
        }
        
        await MainActor.run {
            self.state = .ready
        }
        Self.logger.debug("SpeziLLMOpenAI: OpenAI LLM finished initializing, now ready to use")
        return true
    }
}
