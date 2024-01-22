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


extension LLMOpenAI {
    // swiftlint:disable:next identifier_name function_body_length
    func _generate(continuation: AsyncThrowingStream<String, Error>.Continuation) async throws {
        while true {
            let chatStream: AsyncThrowingStream<ChatStreamResult, Error> = await self.model.chatsStream(query: self.openAIChatQuery)
            
            var llmStreamResults: [LLMOpenAIStreamResult] = []
            
            for try await chatStreamResult in chatStream {
                // Important to iterate over all choices as LLM could choose to call multiple functions
                for choice in chatStreamResult.choices {
                    // Already existing stream result
                    if let existingIndex = llmStreamResults.firstIndex(where: { $0.id == choice.index }) {
                        var existingLLMStreamResult = llmStreamResults[existingIndex]
                        existingLLMStreamResult.append(choice: choice)
                        llmStreamResults[existingIndex] = existingLLMStreamResult
                    // New stream result
                    } else {
                        var newLLMStreamResult = LLMOpenAIStreamResult(id: choice.index)
                        newLLMStreamResult.append(choice: choice)
                        llmStreamResults.append(newLLMStreamResult)
                    }
                }
                
                // Append assistant messages during the streaming to ensure that they are visible to the user during processing
                let assistantContentResults = llmStreamResults.filter { llmStreamResult in
                    llmStreamResult.role == .assistant && !(llmStreamResult.content?.isEmpty ?? true)
                }
                
                // Only consider the first found assistant content result
                guard let content = assistantContentResults.first?.content else {
                    continue
                }
                
                await MainActor.run {
                    self.context.append(assistantOutput: content, overwrite: true)
                }
            }
            
            let functionCalls = llmStreamResults.compactMap { $0.functionCall }
            
            // Exit the while loop if we don't have any function calls.
            guard !functionCalls.isEmpty else {
                break
            }
            
            // Parallelize function call execution
            try await withThrowingTaskGroup(of: Void.self) { group in
                for functionCall in functionCalls {
                    group.addTask {
                        Self.logger.debug("""
                        SpeziLLMOpenAI: Function call \(functionCall.name ?? ""), Arguments: \(functionCall.arguments ?? "")
                        """)

                        guard let functionName = functionCall.name,
                              let functionArgument = functionCall.arguments?.data(using: .utf8),
                              let function = self.functions[functionName] else {
                            Self.logger.debug("SpeziLLMOpenAI: Couldn't find the requested function to call")
                            return
                        }

                        // Inject parameters into the @Parameters of the function call
                        do {
                            try function.injectParameters(from: functionArgument)
                        } catch {
                            throw LLMOpenAIError.invalidFunctionCallArguments(error)
                        }

                        // Execute function
                        // Errors thrown by the functions are surfaced to the user as an LLM generation error
                        let functionCallResponse = try await function.execute()
                        
                        Self.logger.debug("""
                        SpeziLLMOpenAI: Function call \(functionCall.name ?? "") \
                        Arguments: \(functionCall.arguments ?? "") \
                        Response: \(functionCallResponse ?? "<empty response>")
                        """)
                        
                        await MainActor.run {
                            let defaultResponse = "Function call to \(functionCall.name ?? "") succeeded, function intentionally didn't respond anything."

                            // Return `defaultResponse` in case of `nil` or empty return of the function call
                            self.context.append(
                                forFunction: functionName,
                                response: functionCallResponse?.isEmpty != false ? defaultResponse : (functionCallResponse ?? defaultResponse)
                            )
                        }
                    }
                }

                try await group.waitForAll()
            }
        }
    }
}
