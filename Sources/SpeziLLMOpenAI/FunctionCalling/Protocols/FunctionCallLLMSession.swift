//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Atomics
import Foundation
import OSLog
import SpeziLLM


package protocol FunctionCallLLMSession: LLMSession {
    // Logger is required for functions in the FunctionCallLLMSession extension
    static var logger: Logger { get }
    /// The state the LLMSession should return to after completing a tool/function call.
    var toolCallCompletionState: LLMState { get }
    /// Counter to track how many tool (function) calls are currently in progress.
    var toolCallCounter: ManagedAtomic<Int> { get }

    /// Attempts to call a function requested by the LLM.
    /// - Parameters:
    ///   - availableFunctions: A dictionary mapping function names to their corresponding implementations (`LLMFunction`).
    ///   - functionCallArgs: The raw function call request provided by the LLM, including function name, ID, and arguments.
    ///   - failureHandling: Strategy for handling errors if the function call fails (e.g. stop inference, or append error to context).
    ///
    /// - Returns: A `FunctionCallResponse` containing the function call ID, name, arguments, and optional response.
    ///
    /// - Throws: An `LLMError` if the function name, arguments, or execution fails.
    func callFunction(
        availableFunctions: [String: any LLMFunction],
        functionCallArgs: LLMOpenAIStreamResult.FunctionCall,
        failureHandling: FunctionCallLLMSessionTypes.FunctionCallFailureHandling
    ) async throws -> FunctionCallLLMSessionTypes.FunctionCallResponse
}


extension FunctionCallLLMSession {
    // Handles function calls with configurable failure behavior.
    package func callFunction(
        availableFunctions: [String: any LLMFunction],
        functionCallArgs: LLMOpenAIStreamResult.FunctionCall,
        failureHandling: FunctionCallLLMSessionTypes.FunctionCallFailureHandling
    ) async throws -> FunctionCallLLMSessionTypes.FunctionCallResponse {
        do {
            return try await _callFunction(availableFunctions: availableFunctions, functionCallArgs: functionCallArgs)
        } catch let error as any LLMError {
            switch failureHandling {
            case .throwAndStopInference(let continuationObserver):
                await self.finishGenerationWithError(
                    error,
                    on: continuationObserver.continuation
                )
            case .returnErrorInResponse:
                let errorMessage: String
                switch error {
                case LLMOpenAIError.invalidFunctionCallName:
                    errorMessage = "Error - invalid function call name"
                case LLMOpenAIError.invalidFunctionCallArguments(let err):
                    errorMessage = "Error - invalid function call arguments: \(err.localizedDescription)"
                case LLMOpenAIError.functionCallError(let err):
                    errorMessage = "Error - function call execution error: \(err.localizedDescription)"
                default:
                    errorMessage = "Error - unexpected: \(error.localizedDescription)"
                }

                return FunctionCallLLMSessionTypes.FunctionCallResponse(
                        functionID: functionCallArgs.id ?? "",
                        functionName: functionCallArgs.name ?? "",
                        functionArgument: functionCallArgs.arguments ?? "",
                        response: errorMessage
                )
            case .throwError:
                break
            }
            
            throw error
        }
    }
    
    /// Executes a function call.
    ///
    /// This method validates the function name and arguments, injects them into the target function,
    /// executes it asynchronously, and returns the response. It also ensures the tool call counter
    /// is incremented/decremented appropriately for tracking concurrent executions.
    ///
    /// - Throws:
    ///   - `LLMOpenAIError.invalidFunctionCallName` if the function name or ID is missing, or the function is not found.
    ///   - `LLMOpenAIError.invalidFunctionCallArguments` if argument decoding or parameter injection fails.
    ///   - `LLMOpenAIError.functionCallError` if the function itself throws during execution.
    private func _callFunction(
        availableFunctions: [String: any LLMFunction],
        functionCallArgs: LLMOpenAIStreamResult.FunctionCall,
    ) async throws -> FunctionCallLLMSessionTypes.FunctionCallResponse {
        Self.logger.debug("""
        FunctionCallLLMSession: Function call \(functionCallArgs.name ?? "")
        Arguments: \(functionCallArgs.arguments ?? "")
        """)
    
        await self.incrementToolCallCounter()

        guard let functionName = functionCallArgs.name,
              let functionID = functionCallArgs.id,
              let functionArgument = functionCallArgs.arguments?.data(using: .utf8),
              let function = availableFunctions[functionName] else {
            Self.logger.debug("FunctionCallLLMSession: Couldn't find the requested function to call")
            await self.decrementToolCallCounter()
            throw LLMOpenAIError.invalidFunctionCallName
        }
        
        // Inject parameters into the @Parameters of the function call
        do {
            try function.injectParameters(from: functionArgument)
        } catch {
            Self.logger.error(
                "FunctionCallLLMSession: Invalid function call arguments - \(error)"
            )
            await self.decrementToolCallCounter()
            throw LLMOpenAIError.invalidFunctionCallArguments(error)
        }
        
        let functionCallResponseStr: String?

        do {
            // Execute function
            // Errors thrown by the functions are surfaced to the user as an LLM generation error
            functionCallResponseStr = try await function.execute()
        } catch {
            Self.logger.error("FunctionCallLLMSession: Function call execution error - \(error)")
            await self.decrementToolCallCounter()
            throw LLMOpenAIError.functionCallError(error)
        }
        
        Self.logger.debug("""
        FunctionCallLLMSession: Function call \(functionName)
        Arguments: \(functionCallArgs.arguments ?? "")
        Response: \(functionCallResponseStr ?? "<empty response>")
        """)
        
        await self.decrementToolCallCounter()
        
        let defaultResponse = "Function call to \(functionName) succeeded, function intentionally didn't respond anything."
        
        // Return `defaultResponse` in case of `nil` or empty return of the function call
        return FunctionCallLLMSessionTypes.FunctionCallResponse(
            functionID: functionID,
            functionName: functionName,
            functionArgument: functionCallArgs.arguments ?? "",
            response: (functionCallResponseStr?.isEmpty ?? true)
                ? defaultResponse
                : functionCallResponseStr ?? ""
        )
    }
    
    /// Checks if there are active tool calls and updates the state if needed.
    func checkForActiveToolCalls() async {
        if toolCallCounter.load(ordering: .sequentiallyConsistent) == 0 {
            await MainActor.run {
                self.state = toolCallCompletionState
            }
        }
    }

    /// Safely increments the tool call counter and updates the state if needed.
    private func incrementToolCallCounter(by value: Int = 1) async {
        if toolCallCounter.loadThenWrappingIncrement(
            by: value,
            ordering: .sequentiallyConsistent
        ) == 0 {
            await MainActor.run {
                self.state = .callingTools
            }
        }
    }

    /// Safely decrements the tool call counter and updates the state if needed.
    private func decrementToolCallCounter() async {
        if toolCallCounter.loadThenWrappingDecrement(
            by: 1,
            ordering: .sequentiallyConsistent
        ) == 1 {
            await MainActor.run {
                self.state = toolCallCompletionState
            }
        }
    }
}
