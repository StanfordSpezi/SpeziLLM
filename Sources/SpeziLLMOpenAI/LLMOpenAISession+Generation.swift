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
import SpeziLLM


extension LLMOpenAISession {
    /// Based on the input prompt, generate the output via the OpenAI API.
    ///
    /// - Parameters:
    ///   - continuation: A Swift `AsyncThrowingStream` that streams the generated output.
    func _generate( // swiftlint:disable:this identifier_name function_body_length cyclomatic_complexity
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async {
        Self.logger.debug("SpeziLLMOpenAI: OpenAI GPT started a new inference")
        await MainActor.run {
            self.state = .generating
        }
        
        while true {
            var llmStreamResults: [Int: LLMOpenAIStreamResult] = [:]
            
            do {
                let response = try await chatGPTClient.createChatCompletion(openAIChatQuery)

                // FIXME: does not handle the "[DONE]" message
                let chatStream = try response.ok.body.text_event_hyphen_stream
                    .asDecodedServerSentEventsWithJSONData(of: Components.Schemas.CreateChatCompletionStreamResponse
                        .self)

                chatStreamIteration: for try await chatStreamResult in chatStream {
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
                    
                    guard await !checkCancellation(on: continuation) else {
                        Self.logger.debug("SpeziLLMOpenAI: LLM inference cancelled because of Task cancellation.")
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
                
                if schema.injectIntoContext {
                    await MainActor.run {
                        context.completeAssistantStreaming()
                    }
                }

                // FIXME: what is the counterpart for the generated API calls?
                // } catch let error as APIErrorResponse {
                // switch error.error.code {
                // case LLMOpenAIError.invalidAPIToken.openAIErrorMessage:
                //     Self.logger.error("SpeziLLMOpenAI: Invalid OpenAI API token - \(error)")
                //     await finishGenerationWithError(LLMOpenAIError.invalidAPIToken, on: continuation)
                // case LLMOpenAIError.insufficientQuota.openAIErrorMessage:
                //     Self.logger.error("SpeziLLMOpenAI: Insufficient OpenAI API quota - \(error)")
                //     await finishGenerationWithError(LLMOpenAIError.insufficientQuota, on: continuation)
                // default:
                //     Self.logger.error("SpeziLLMOpenAI: Generation error occurred - \(error)")
                //     await finishGenerationWithError(LLMOpenAIError.generationError, on: continuation)
                // }
                // return
            } catch let error as URLError {
                Self.logger.error("SpeziLLMOpenAI: Connectivity Issues with the OpenAI API: \(error)")
                await finishGenerationWithError(LLMOpenAIError.connectivityIssues(error), on: continuation)
                return
            } catch let Swift.DecodingError.dataCorrupted(context) {
                // FIXME: The API sends a "[DONE]" message to conclude the stream. As it does not conform to the Components.Schemas.CreateChatCompletionStreamResponse schema, it will cause a crash. This is a hacky workaround to avoid the crash.
            } catch {
                Self.logger.error("SpeziLLMOpenAI: Generation error occurred - \(error)")
                await finishGenerationWithError(LLMOpenAIError.generationError, on: continuation)
                return
            }

            // FIXME: Swiftformat bug?
            // swiftformat:disable all
            let functionCalls = llmStreamResults.values.compactMap{ return $0.functionCall }.flatMap { $0 }
            // swiftformat:enable all

            // Exit the while loop if we don't have any function calls
            guard !functionCalls.isEmpty else {
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
            
            // Parallelize function call execution
            do {
                try await withThrowingTaskGroup(of: Void.self) { group in   // swiftlint:disable:this closure_body_length
                    for functionCall in functionCalls {
                        group.addTask {     // swiftlint:disable:this closure_body_length
                            Self.logger.debug("""
                            SpeziLLMOpenAI: Function call \(functionCall.name ?? "")
                            Arguments: \(functionCall.arguments ?? "")
                            """)

                            guard let functionName = functionCall.name,
                                  let functionID = functionCall.id,
                                  let functionArgument = functionCall.arguments?.data(using: .utf8),
                                  let function = self.schema.functions[functionName] else {
                                Self.logger.debug("SpeziLLMOpenAI: Couldn't find the requested function to call")
                                await self.finishGenerationWithError(LLMOpenAIError.invalidFunctionCallName, on: continuation)
                                throw LLMOpenAIError.invalidFunctionCallName
                            }

                            // Inject parameters into the @Parameters of the function call
                            do {
                                try function.injectParameters(from: functionArgument)
                            } catch {
                                Self.logger.error("SpeziLLMOpenAI: Invalid function call arguments - \(error)")
                                await self.finishGenerationWithError(LLMOpenAIError.invalidFunctionCallArguments(error), on: continuation)
                                throw LLMOpenAIError.invalidFunctionCallArguments(error)
                            }

                            let functionCallResponse: String?
                            
                            do {
                                // Execute function
                                // Errors thrown by the functions are surfaced to the user as an LLM generation error
                                functionCallResponse = try await function.execute()
                            } catch is CancellationError {
                                guard await !self.checkCancellation(on: continuation) else {
                                    Self.logger.debug("SpeziLLMOpenAI: Function call execution cancelled because of Task cancellation.")
                                    throw CancellationError()
                                }
                                return
                            } catch {
                                Self.logger.error("SpeziLLMOpenAI: Function call execution error - \(error)")
                                await self.finishGenerationWithError(LLMOpenAIError.functionCallError(error), on: continuation)
                                throw LLMOpenAIError.functionCallError(error)
                            }
                            
                            Self.logger.debug("""
                            SpeziLLMOpenAI: Function call \(functionCall.name ?? "")
                            Arguments: \(functionCall.arguments ?? "")
                            Response: \(functionCallResponse ?? "<empty response>")
                            """)
                            
                            await MainActor.run {
                                let defaultResponse = "Function call to \(functionCall.name ?? "") succeeded, function intentionally didn't respond anything."

                                // Return `defaultResponse` in case of `nil` or empty return of the function call
                                self.context.append(
                                    forFunction: functionName,
                                    withID: functionID,
                                    response: functionCallResponse?.isEmpty != false ? defaultResponse : (functionCallResponse ?? defaultResponse)
                                )
                            }
                        }
                    }

                    try await group.waitForAll()
                }
            } catch {
                // Stop LLM inference in case of a function call error
                return
            }
        }
        
        continuation.finish()
        Self.logger.debug("SpeziLLMOpenAI: OpenAI GPT completed an inference")
        
        await MainActor.run {
            self.state = .ready
        }
    }
}
