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
import SpeziChat


extension LLMFogSession {
    /// Based on the input prompt, generate the output via some OpenAI API, e.g., Ollama.
    ///
    /// - Parameters:
    ///   - continuation: A Swift `AsyncThrowingStream` that streams the generated output.
    func _generate( // swiftlint:disable:this identifier_name function_body_length cyclomatic_complexity
        continuation: AsyncThrowingStream<String, any Error>.Continuation
    ) async {
        Self.logger.debug("SpeziLLMFog: Fog LLM started a new inference")
        await MainActor.run {
            self.state = .generating
        }
        do {
            let response = try await fogNodeClient.createChatCompletion(openAIChatQuery)

            if case let .undocumented(statusCode: statusCode, payload) = response {
                var errorMessage: String?
                if let body = payload.body,
                   let bodyData = try? await ArraySlice(collecting: body, upTo: 8 * 1024),
                   let bodyString = String(data: Data(bodyData), encoding: .utf8) {
                    errorMessage = bodyString
                }

                let llmError = handleErrorCode(statusCode: statusCode, message: errorMessage)
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
                guard let firstChoice = choices.first,
                      firstChoice.delta.role == .assistant,
                      let content = firstChoice.delta.content,
                      !content.isEmpty else {
                    continue
                }

                // Automatically inject the yielded string piece into the `LLMLocal/context`
                if schema.injectIntoContext {
                    await MainActor.run {
                        context.append(assistantOutput: content)
                    }
                }

                if case .terminated = continuation.yield(content) {
                    Self.logger.error("SpeziLLMFog: Generation cancelled by the user.")

                    // break the loop, no other cleanup needed
                    break
                }
            }

            continuation.finish()

            if schema.injectIntoContext {
                await MainActor.run {
                    context.completeAssistantStreaming()
                }
            }
        } catch let error as ClientError {
            Self.logger.error("SpeziLLMFog: Connectivity Issues with the Fog Node: \(error)")
            await finishGenerationWithError(LLMFogError.connectivityIssues(error), on: continuation)
            return
        } catch {
            Self.logger.error("SpeziLLMFog: Unknown Generation error occurred - \(error)")
            await finishGenerationWithError(LLMFogError.unknownError(error.localizedDescription), on: continuation)
            return
        }

        Self.logger.debug("SpeziLLMFog: Fog LLM completed an inference")

        await MainActor.run {
            self.state = .ready
        }
    }
}
