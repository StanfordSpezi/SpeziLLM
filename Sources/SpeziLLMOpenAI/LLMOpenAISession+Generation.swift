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
import SpeziLLM


extension LLMOpenAISession {
    /// Based on the input prompt, generate the output via the OpenAI API.
    ///
    /// - Parameters:
    ///   - continuation: A Swift `AsyncThrowingStream` that streams the generated output.
    func _generate( // swiftlint:disable:this identifier_name function_body_length cyclomatic_complexity
        continuation: AsyncThrowingStream<String, any Error>.Continuation
    ) async {
        Self.logger.debug("SpeziLLMOpenAI: OpenAI GPT started a new inference")
        await MainActor.run {
            self.state = .generating
        }
        
        while true {
            let chatStream: AsyncThrowingStream<ChatStreamResult, any Error> = await self.model.chatsStream(query: self.openAIChatQuery)
            
            var llmStreamResults: [Int: LLMOpenAIStreamResult] = [:]
            
            do {
                for try await chatStreamResult in chatStream {
                    // Important to iterate over all choices as LLM could choose to call multiple functions / generate multiple choices
                    for choice in chatStreamResult.choices {
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
                    
                    if await checkCancellation(on: continuation) {
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
            } catch let error as APIErrorResponse {
                switch error.error.code {
                case LLMOpenAIError.invalidAPIToken.openAIErrorMessage:
                    Self.logger.error("SpeziLLMOpenAI: Invalid OpenAI API token - \(error)")
                    await finishGenerationWithError(LLMOpenAIError.invalidAPIToken, on: continuation)
                case LLMOpenAIError.insufficientQuota.openAIErrorMessage:
                    Self.logger.error("SpeziLLMOpenAI: Insufficient OpenAI API quota - \(error)")
                    await finishGenerationWithError(LLMOpenAIError.insufficientQuota, on: continuation)
                default:
                    Self.logger.error("SpeziLLMOpenAI: Generation error occurred - \(error)")
                    await finishGenerationWithError(LLMOpenAIError.generationError, on: continuation)
                }
                return
            } catch let error as URLError {
                Self.logger.error("SpeziLLMOpenAI: Connectivity Issues with the OpenAI API: \(error)")
                await finishGenerationWithError(LLMOpenAIError.connectivityIssues(error), on: continuation)
                return
            } catch {
                Self.logger.error("SpeziLLMOpenAI: Generation error occurred - \(error)")
                await finishGenerationWithError(LLMOpenAIError.generationError, on: continuation)
                return
            }

            let functionCalls = llmStreamResults.values.compactMap { $0.functionCall }.flatMap { $0 }
            
            // Exit the while loop if we don't have any function calls
            guard !functionCalls.isEmpty else {
                break
            }
            
            // Inject the requested function calls into the LLM context
            let functionCallContext: [LLMContextEntity.ToolCall] = functionCalls.compactMap { functionCall in
                guard let functionCallId = functionCall.id,
                      let functionCallName = functionCall.name else {
                    return nil
                }
                
                return .init(id: functionCallId, name: functionCallName, arguments: functionCall.arguments ?? "")
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
                                if await self.checkCancellation(on: continuation) {
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
