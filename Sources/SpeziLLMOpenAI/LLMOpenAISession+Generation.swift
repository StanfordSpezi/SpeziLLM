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
import SpeziLLM


extension LLMOpenAISession {
    /// Based on the input prompt, generate the output via the OpenAI API.
    ///
    /// - Parameters:
    ///   - continuationObserver: A `ContinuationObserver` that tracks a Swift `AsyncThrowingStream` continuation for cancellation.
    func _generate( // swiftlint:disable:this identifier_name function_body_length cyclomatic_complexity
        with continuationObserver: ContinuationObserver<String, any Error>
    ) async {
        // Check if the generation has been cancelled
        if continuationObserver.isCancelled {
            Self.logger.warning("SpeziLLMOpenAI: Generation cancelled by the user.")
            return
        }

        Self.logger.debug("SpeziLLMOpenAI: OpenAI GPT started a new inference")
        await MainActor.run {
            self.state = .generating
        }

        while true {
            // Check if the generation has been cancelled
            if continuationObserver.isCancelled {
                Self.logger.warning("SpeziLLMOpenAI: Generation cancelled by the user.")
                break
            }

            var llmStreamResults: [Int: LLMOpenAIStreamResult] = [:]
            
            do {
                let response = try await openAiClient.createChatCompletion(openAIChatQuery)

                if case let .undocumented(statusCode: statusCode, _) = response {
                    let llmError = handleErrorCode(statusCode)
                    await finishGenerationWithError(llmError, on: continuationObserver.continuation)
                    return
                }

                let chatStream = try response.ok.body.text_event_hyphen_stream
                    .asDecodedServerSentEventsWithJSONData(
                        of: Components.Schemas.CreateChatCompletionStreamResponse.self,
                        decoder: .init(),
                        while: { incomingData in incomingData != ArraySlice<UInt8>(Data("[DONE]".utf8)) }
                    )

                for try await chatStreamResult in chatStream {
                    // Check if the generation has been cancelled
                    if continuationObserver.isCancelled {
                        Self.logger.warning("SpeziLLMOpenAI: Generation cancelled by the user.")

                        // cleanup, discard any results so that we don't perform function calls
                        llmStreamResults = [:]
                        break
                    }

                    guard let choices = chatStreamResult.data?.choices else {
                        Self.logger.error("SpeziLLMOpenAI: Couldn't obtain choices from stream response.")
                        return
                    }

                    // Important to iterate over all choices as LLM could choose to call multiple functions / generate multiple choices
                    for choice in choices {
                        llmStreamResults[choice.index] = llmStreamResults[
                            choice.index,
                            default: .init()
                        ].append(choice: choice)
                    }
                    
                    // Append assistant messages during the streaming to ensure that they are visible to the user during processing
                    let assistantResults = llmStreamResults.values.filter { llmStreamResult in
                        llmStreamResult.role == .assistant && !(llmStreamResult.deltaContent?.isEmpty ?? true)
                    }
                    
                    // Only consider the first found assistant content result
                    guard let content = assistantResults.first?.deltaContent else {
                        continue
                    }

                    // Automatically inject the yielded string piece into the `LLMLocal/context`
                    if schema.injectIntoContext {
                        await MainActor.run {
                            context.append(assistantOutput: content)
                        }
                    }

                    // Yield string piece into continuation
                    continuationObserver.continuation.yield(content)
                }
                
                if schema.injectIntoContext {
                    await MainActor.run {
                        context.completeAssistantStreaming()
                    }
                }
            } catch let error as ClientError {
                Self.logger.error("SpeziLLMOpenAI: Connectivity Issues with the OpenAI API: \(error)")
                await finishGenerationWithError(LLMOpenAIError.connectivityIssues(error), on: continuationObserver.continuation)
                return
            } catch let error as LLMOpenAIError {
                Self.logger.error("SpeziLLMOpenAI: \(error.localizedDescription)")
                await finishGenerationWithError(LLMOpenAIError.functionCallSchemaExtractionError(error), on: continuationObserver.continuation)
                return
            } catch {
                Self.logger.error("SpeziLLMOpenAI: Unknown Generation error occurred - \(error)")
                await finishGenerationWithError(LLMOpenAIError.generationError, on: continuationObserver.continuation)
                return
            }

            let functionCalls = llmStreamResults.values.compactMap { $0.functionCall }.flatMap { $0 }

            // Exit the while loop if we don't have any function calls
            guard !functionCalls.isEmpty else {
                await checkForActiveToolCalls()
                break
            }
            
            // Inject the requested function calls into the LLM context
            let functionCallContext: [LLMContextEntity.ToolCall] = functionCalls.compactMap { functionCall in
                guard let functionCallID = functionCall.id,
                      let functionCallName = functionCall.name else {
                    return nil
                }

                return .init(id: functionCallID, name: functionCallName, arguments: functionCall.arguments ?? "")
            }
            await MainActor.run {
                context.append(functionCalls: functionCallContext)
            }

            // Parallel function call execution
            do {
                try await withThrowingTaskGroup(of: Void.self) { group in
                    for functionCall in functionCalls {
                        group.addTask {
                            // Check if the function call execution has been cancelled
                            if continuationObserver.isCancelled {
                                Self.logger.warning("SpeziLLMOpenAI: Function call execution cancelled by the user.")
                                return
                            }
                            
                            let functionCallResponse = try? await self.callFunction(
                                availableFunctions: self.schema.functions,
                                functionCallArgs: functionCall,
                                failureHandling: .returnErrorInResponse
                            )

                            guard let functionCallResponse = functionCallResponse else {
                                Self.logger.warning("SpeziLLMOpenAI: callFunction() threw an error.")
                                return
                            }

                            await MainActor.run {
                                self.context.append(
                                    forFunction: functionCallResponse.functionName,
                                    withID: functionCallResponse.functionID,
                                    response: functionCallResponse.response
                                )
                            }
                        }
                    }
                    
                    try await group.waitForAll()
                }
            } catch {
                // Stop LLM inference in case of an unexpected error during the function call
                return
            }
        }

        Self.logger.debug("SpeziLLMOpenAI: OpenAI GPT completed an inference")

        await MainActor.run {
            self.state = .ready
        }
    }
}
