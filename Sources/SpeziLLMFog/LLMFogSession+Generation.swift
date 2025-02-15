//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import OpenAPIRuntime
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
    func _generate( // swiftlint:disable:this identifier_name
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async {
        Self.logger.debug("SpeziLLMFog: Fog LLM started a new inference")
        await MainActor.run {
            self.state = .generating
        }

        do {
            let response = try await chatGPTClient.createChatCompletion(openAIChatQuery)

            if case let .undocumented(statusCode: statusCode, _) = response {
                Self.logger.error("SpeziLLMFog: Error during generation. Status code: \(statusCode)")
                let llmError = handleErrorCode(statusCode)
                await finishGenerationWithError(llmError, on: continuation)
                return
            }

            let chatStream = try response.ok.body.text_event_hyphen_stream
                .asDecodedServerSentEventsWithJSONData(
                    of: Components.Schemas.CreateChatCompletionStreamResponse.self,
                    decoder: .init(),
                    while: { incomingData in incomingData != ArraySlice<UInt8>(Data("[DONE]".utf8)) }
                )

            for try await chatStreamResult in chatStream {
                guard let choices = chatStreamResult.data?.choices else {
                    Self.logger.error("SpeziLLMFog: Couldn't obtain choices from stream response.")
                    return
                }

                // Only consider the first found assistant content result
                // todo: check if that really works, not 100% sure
                guard let firstChoice = choices.first,
                      firstChoice.delta.role == .assistant,
                      let content = firstChoice.delta.content,
                      !content.isEmpty else {
                    continue
                }

                if await checkCancellation(on: continuation) {
                    Self.logger.debug("SpeziLLMFog: LLM inference cancelled because of Task cancellation.")
                    return
                }

                // Automatically inject the yielded string piece into the `LLMLocal/context`
                if schema.injectIntoContext {
                    await MainActor.run {
                        context.append(assistantOutput: content)
                    }
                }

                continuation.yield(content)
            }

            continuation.finish()

            if schema.injectIntoContext {
                await MainActor.run {
                    context.completeAssistantStreaming()
                }
            }
        } catch let error as URLError {
            Self.logger.error("SpeziLLMFog: Connectivity Issues with the Fog Node: \(error)")
            await finishGenerationWithError(LLMFogError.connectivityIssues(error), on: continuation)
            return
        } catch {
            Self.logger.error("SpeziLLMFog: Unknwon Generation error occurred - \(error)")
            await finishGenerationWithError(LLMFogError.generationError, on: continuation)
            return
        }

        Self.logger.debug("SpeziLLMFog: Fog LLM completed an inference")

        await MainActor.run {
            self.state = .ready
        }
    }
}
