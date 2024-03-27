//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import OpenAI
import SpeziChat


extension LLMFogSession {
    private static let modelNotFoundRegex: Regex = {
        guard let regex = try? Regex("model '([\\w:]+)' not found, try pulling it first") else {
            preconditionFailure("SpeziLLMFog: Error Regex could not be parsed")
        }
        
        return regex
    }()

    
    /// Based on the input prompt, generate the output via some OpenAI API, e.g., Ollama.
    ///
    /// - Parameters:
    ///   - continuation: A Swift `AsyncThrowingStream` that streams the generated output.
    func _generate( // swiftlint:disable:this identifier_name function_body_length
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async {
        Self.logger.debug("SpeziLLMFog: Fog LLM started a new inference")
        await MainActor.run {
            self.state = .generating
        }
        
        // Check if the node is still active by pinging it
        guard await ensureFogNodeAvailability(continuation: continuation) else {
            return
        }
        
        let chatStream: AsyncThrowingStream<ChatStreamResult, Error> = await self.model.chatsStream(query: self.openAIChatQuery)
        
        do {
            for try await streamResult in chatStream {
                guard await !checkCancellation(on: continuation) else {
                    Self.logger.debug("SpeziLLMFog: LLM inference cancelled because of Task cancellation.")
                    return
                }
                
                let outputPiece = streamResult.choices.first?.delta.content ?? ""
                
                if schema.injectIntoContext {
                    await MainActor.run {
                        context.append(assistantOutput: outputPiece)
                    }
                }
                
                continuation.yield(outputPiece)
            }
            
            continuation.finish()
            if schema.injectIntoContext {
                await MainActor.run {
                    context.completeAssistantStreaming()
                }
            }
        } catch let error as APIErrorResponse {
            // Sadly, there's no better way to check the error messages as there aren't any Ollama error codes as with the OpenAI API
            if error.error.message.contains(Self.modelNotFoundRegex) {
                Self.logger.error("SpeziLLMFog: LLM model type could not be accessed on fog node - \(error.error.message)")
                await finishGenerationWithError(LLMFogError.modelAccessError(error), on: continuation)
            } else if error.error.code == "401" || error.error.code == "403" {
                Self.logger.error("SpeziLLMFog: LLM model could not be accessed as the Firebase User ID token is invalid.")
                await finishGenerationWithError(LLMFogError.invalidAPIToken, on: continuation)
            } else {
                Self.logger.error("SpeziLLMFog: Generation error occurred - \(error)")
                await finishGenerationWithError(LLMFogError.generationError, on: continuation)
            }
            return
        } catch let error as URLError {
            Self.logger.error("SpeziLLMFog: Connectivity Issues with the Fog Node: \(error)")
            await finishGenerationWithError(LLMFogError.connectivityIssues(error), on: continuation)
            return
        } catch {
            Self.logger.error("SpeziLLMFog: Generation error occurred - \(error)")
            await finishGenerationWithError(LLMFogError.generationError, on: continuation)
            return
        }
        
        Self.logger.debug("SpeziLLMFog: Fog LLM completed an inference")
        
        await MainActor.run {
            self.state = .ready
        }
    }
    
    private func ensureFogNodeAvailability(continuation: AsyncThrowingStream<String, Error>.Continuation) async -> Bool {
        guard let discoveredServiceAddress,
              let discoveredServiceAddressUrl = URL(string: discoveredServiceAddress) else {
            Self.logger.error("SpeziLLMFog: mDNS service could not be resolved to an IP.")
            await finishGenerationWithError(LLMFogError.mDnsServicesNotFound, on: continuation)
            return false
        }
        
        do {
            _ = try await URLSession.shared.data(from: discoveredServiceAddressUrl)
        } catch {
            // If node not reachable anymore, try to discover another fog node, otherwise fail
            guard await setup(continuation: continuation) else {
                Self.logger.error("SpeziLLMFog: mDNS service could not be resolved to an IP.")
                await finishGenerationWithError(LLMFogError.mDnsServicesNotFound, on: continuation)
                return false
            }
        }
        
        return true
    }
}
