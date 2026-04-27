//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable file_types_order

import Foundation
import GeneratedOpenAIClient
import OpenAPIRuntime
import SpeziChat
import SpeziLLM


extension LLMOpenAILikeSession {
    /// Generates a response using the OpenAI Responses API (`POST /v1/responses`).
    ///
    /// This method is the Responses API equivalent of `_generate(with:)` for Chat Completions.
    /// It handles streaming SSE events, text deltas, function calls, and multi-turn via `previous_response_id`.
    func _generateWithResponses( // swiftlint:disable:this identifier_name function_body_length cyclomatic_complexity
        with continuationObserver: ContinuationObserver<String, any Error>
    ) async {
        if continuationObserver.isCancelled {
            Self.logger.warning("SpeziLLMOpenAI: Generation cancelled by the user.")
            return
        }
        
        /// unique ID for this user interaction with the LLM. used to group together all resulting context entities.
        let interactionId = LLMInteractionId()
        
        await MainActor.run {
            self.state = .generating
        }
        
        while true {
            guard !continuationObserver.isCancelled else {
                Self.logger.warning("SpeziLLMOpenAI: Generation cancelled by the user.")
                await MainActor.run {
                    context.removeIncompleteAssistantThinking(for: interactionId)
                }
                break
            }
            var functionCalls: [LLMOpenAIStreamResult.FunctionCall] = []
            do {
                let response = try await openAiClient.createResponse(openAIResponsesQuery)
                if case let .undocumented(statusCode: statusCode, payload) = response {
                    let llmError = handleErrorCode(statusCode)
                    #if DEBUG
                    if let body = payload.body, case let .known(length) = body.length {
                        let buffer = try await Data(collecting: body, upTo: Int(length))
                        let text = String(data: buffer, encoding: .utf8) ?? "<non-UTF8 body>"
                        Self.logger.warning("SpeziLLMOpenAI: Undocumented request body:\n\(text)")
                    }
                    #endif
                    await finishGenerationWithError(llmError, on: continuationObserver.continuation)
                    return
                }
                
                let eventStream = try response.ok.body
                    .text_event_hyphen_stream
                    .asDecodedServerSentEvents()
                
                for try await event in eventStream {
                    if continuationObserver.isCancelled {
                        Self.logger.warning("SpeziLLMOpenAI: Generation cancelled by the user.")
                        functionCalls = []
                        break
                    }
                    guard let jsonData = event.data?.data(using: .utf8),
                          let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                          let eventType = dict["type"] as? String else {
                        continue
                    }
                    guard let eventType = ResponseStreamEventType(rawValue: eventType) else {
                        Self.logger.error("Encountered unknown event: \(eventType)")
                        continue
                    }
                    switch eventType {
                    case .responseCreated:
                        await MainActor.run {
                            context.beginAssistantThinkingPlaceholder(with: interactionId)
                        }
                    case .responseOutputTextDelta:
                        guard let delta = dict["delta"] as? String else {
                            continue
                        }
                        // first content token signals end of thinking phase.
                        await MainActor.run {
                            context.completeAssistantThinkingStreaming(for: interactionId)
                            if schema.injectIntoContext {
                                context.append(assistantOutputDelta: delta, isComplete: false, interactionId: interactionId)
                            }
                        }
                        continuationObserver.continuation.yield(delta)
                    case .responseOutputTextDone:
                        if schema.injectIntoContext {
                            await MainActor.run {
                                context.markAssistantOutputCompleted()
                            }
                        }
                    case .responseOutputItemDone:
                        // Function calls are streamed across multiple events. The `function_call_arguments.delta`
                        // and `.done` events only carry an `item_id` and the (partial) arguments string —
                        // notably NOT the function name in practice, despite the API spec marking it required.
                        // Use `response.output_item.done` instead: it carries the fully-finalized OutputItem,
                        // which for function_call items has `call_id`, `name`, and the complete `arguments`
                        // JSON string in one place.
                        guard let item = dict["item"] as? [String: Any],
                              item["type"] as? String == "function_call" else {
                            continue
                        }
                        guard let callId = item["call_id"] as? String,
                              let name = item["name"] as? String,
                              let arguments = item["arguments"] as? String else {
                            Self.logger.warning("SpeziLLMOpenAI: Incomplete function_call output item: \(item)")
                            continue
                        }
                        functionCalls.append(
                            LLMOpenAIStreamResult.FunctionCall(name: name, id: callId, arguments: arguments)
                        )
                    case .responseReasoningSummaryPartAdded:
                        // Idempotent against the placeholder we created above; only creates a new entity
                        // when the previous part is already complete (i.e. starting a subsequent part).
                        await MainActor.run {
                            context.beginAssistantThinkingPlaceholder(with: interactionId)
                        }
                    case .responseReasoningSummaryTextDelta:
                        guard let delta = dict["delta"] as? String else {
                            continue
                        }
                        await MainActor.run {
                            context.append(assistantThinkingDelta: delta, interactionId: interactionId)
                        }
                    case .responseReasoningSummaryTextDone, .responseReasoningSummaryPartDone:
                        await MainActor.run {
                            context.completeAssistantThinkingStreaming(for: interactionId)
                        }
                    case .responseCompleted:
                        // Extract response ID for multi-turn support
                        if let responseObj = dict["response"] as? [String: Any],
                           let responseId = responseObj["id"] as? String {
                            self.lastResponseId = responseId
                        }
                    case .responseFailed:
                        let errorMsg = (dict["response"] as? [String: Any])?["error"] as? [String: Any]
                        let message = errorMsg?["message"] as? String ?? "Unknown error"
                        Self.logger.error("SpeziLLMOpenAI: Response failed: \(message)")
                        await MainActor.run {
                            context.removeIncompleteAssistantThinking(for: interactionId)
                        }
                        await finishGenerationWithError(LLMOpenAIError.generationError, on: continuationObserver.continuation)
                        return
                    default:
                        // some other event that either doesn't need handling, or is not supported by us.
                        break
                    }
                }
                
                // Stream ended for this iteration. Make sure no thinking placeholder is left dangling — e.g. if
                // the model responded with only a function call and no reasoning summary parts. If the stream
                // ended due to cancellation, remove the unfinished placeholder entirely instead of marking
                // it complete.
                await MainActor.run {
                    if continuationObserver.isCancelled {
                        context.removeIncompleteAssistantThinking(for: interactionId)
                    } else {
                        context.completeAssistantThinkingStreaming(for: interactionId)
                    }
                }
            } catch let error as ClientError {
                Self.logger.error("SpeziLLMOpenAI: Connectivity Issues with the OpenAI API: \(error)")
                await MainActor.run {
                    context.removeIncompleteAssistantThinking(for: interactionId)
                }
                await finishGenerationWithError(LLMOpenAIError.connectivityIssues(error), on: continuationObserver.continuation)
                return
            } catch let error as LLMOpenAIError {
                Self.logger.error("SpeziLLMOpenAI: \(error.localizedDescription)")
                await MainActor.run {
                    context.removeIncompleteAssistantThinking(for: interactionId)
                }
                await finishGenerationWithError(LLMOpenAIError.functionCallSchemaExtractionError(error), on: continuationObserver.continuation)
                return
            } catch {
                Self.logger.error("SpeziLLMOpenAI: Unknown Generation error occurred - \(error)")
                await MainActor.run {
                    context.removeIncompleteAssistantThinking(for: interactionId)
                }
                await finishGenerationWithError(LLMOpenAIError.generationError, on: continuationObserver.continuation)
                return
            }
            
            // Exit the while loop if we don't have any function calls
            guard !functionCalls.isEmpty else {
                await checkForActiveToolCalls()
                break
            }
            
            // Inject the requested function calls into the LLM context
            let functionCallContext: [LLMContextEntity.ToolCall] = functionCalls.compactMap { functionCall in
                guard let functionCallName = functionCall.name else {
                    return nil
                }
                return .init(id: functionCall.id ?? "", name: functionCallName, arguments: functionCall.arguments ?? "")
            }
            await MainActor.run {
                context.append(toolCalls: functionCallContext, interactionId: interactionId)
            }
            
            // Parallel function call execution
            do {
                try await withThrowingTaskGroup(of: Void.self) { group in
                    for functionCall in functionCalls {
                        group.addTask {
                            guard !continuationObserver.isCancelled else {
                                return
                            }
                            let response = try? await self.callFunction(
                                availableFunctions: self.schema.functions,
                                functionCallArgs: functionCall,
                                failureHandling: .returnErrorInResponse
                            )
                            guard let response else {
                                return
                            }
                            await MainActor.run {
                                self.context.append(
                                    toolCallResponse: response.response,
                                    for: response.functionName,
                                    withId: response.functionID,
                                    interactionId: interactionId
                                )
                            }
                        }
                    }
                    try await group.waitForAll()
                }
            } catch {
                return
            }
        }
        
        await MainActor.run {
            self.state = .ready
        }
    }
}


/// All server-sent event types emitted when streaming an OpenAI Responses API response.
private enum ResponseStreamEventType: String, Sendable, Hashable {
    // MARK: Response Lifecycle
    /// Response object created, status `in_progress`.
    case responseCreated = "response.created"
    /// Generation has started.
    case responseInProgress = "response.in_progress"
    /// Generation finished successfully.
    case responseCompleted = "response.completed"
    /// Generation failed (check the `error` field on the response).
    case responseFailed = "response.failed"
    /// Generation stopped early (e.g. max output tokens reached).
    case responseIncomplete = "response.incomplete"
    /// Response is queued for processing (background mode).
    case responseQueued = "response.queued"
    
    // MARK: Output Items
    /// A new item was appended to the response's `output` array (message, function_call, reasoning, etc.).
    case responseOutputItemAdded = "response.output_item.added"
    /// An output item has been finalized.
    case responseOutputItemDone = "response.output_item.done"
    
    // MARK: Content Parts
    /// A new content part was added to a message item's `content` array.
    case responseContentPartAdded = "response.content_part.added"
    /// A content part has been finalized.
    case responseContentPartDone = "response.content_part.done"
    
    // MARK: Text Output
    /// An incremental text token delta.
    case responseOutputTextDelta = "response.output_text.delta"
    /// A citation or annotation was added to the text output.
    case responseOutputTextAnnotationAdded = "response.output_text.annotation.added"
    /// The text content part is complete.
    case responseOutputTextDone = "response.output_text.done"
    
    // MARK: Refusal
    /// An incremental refusal text delta.
    case responseRefusalDelta = "response.refusal.delta"
    /// The refusal content is complete.
    case responseRefusalDone = "response.refusal.done"
    
    // MARK: Function Calling
    /// An incremental delta of the JSON-encoded function call arguments.
    case responseFunctionCallArgumentsDelta = "response.function_call_arguments.delta"
    /// The function call arguments are complete.
    case responseFunctionCallArgumentsDone = "response.function_call_arguments.done"
    
    // MARK: Custom Tool Calls (MCP, etc.)
    /// An incremental input delta for a custom tool call.
    case responseCustomToolCallInputDelta = "response.custom_tool_call_input.delta"
    /// The custom tool call input is complete.
    case responseCustomToolCallInputDone = "response.custom_tool_call_input.done"
    
    // MARK: File Search
    /// A file search tool call has started.
    case responseFileSearchCallInProgress = "response.file_search_call.in_progress"
    /// The file search tool call is actively searching.
    case responseFileSearchCallSearching = "response.file_search_call.searching"
    /// The file search tool call has completed with results.
    case responseFileSearchCallCompleted = "response.file_search_call.completed"
    
    // MARK: Code Interpreter
    /// A code interpreter tool call has started.
    case responseCodeInterpreterCallInProgress = "response.code_interpreter_call.in_progress"
    /// An incremental delta of the generated code.
    case responseCodeInterpreterCallCodeDelta = "response.code_interpreter_call.code.delta"
    /// The generated code is complete.
    case responseCodeInterpreterCallCodeDone = "response.code_interpreter_call.code.done"
    /// The code interpreter is executing the generated code.
    case responseCodeInterpreterCallInterpreting = "response.code_interpreter_call.interpreting"
    /// The code interpreter tool call has completed execution.
    case responseCodeInterpreterCallCompleted = "response.code_interpreter_call.completed"
    
    // MARK: Web Search
    /// A web search tool call has started.
    case responseWebSearchCallInProgress = "response.web_search_call.in_progress"
    /// The web search tool call is actively searching.
    case responseWebSearchCallSearching = "response.web_search_call.searching"
    /// The web search tool call has completed with results.
    case responseWebSearchCallCompleted = "response.web_search_call.completed"
    
    // MARK: Reasoning (o-series models)
    /// A reasoning summary part was added.
    case responseReasoningSummaryPartAdded = "response.reasoning_summary_part.added"
    /// A reasoning summary part has been finalized.
    case responseReasoningSummaryPartDone = "response.reasoning_summary_part.done"
    /// An incremental delta of the reasoning summary text.
    case responseReasoningSummaryTextDelta = "response.reasoning_summary_text.delta"
    /// The reasoning summary text is complete.
    case responseReasoningSummaryTextDone = "response.reasoning_summary_text.done"
    
    // MARK: Error
    /// An error occurred during streaming.
    case error = "error"
}
