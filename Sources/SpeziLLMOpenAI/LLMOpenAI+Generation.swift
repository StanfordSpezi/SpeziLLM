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
            
            var llmStreamResults: [Int: LLMOpenAIStreamResult] = [:]
            
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
                
                // Automatically inject the yielded string piece into the `LLMLocal/context`
                if injectIntoContext {
                    await MainActor.run {
                        context.append(assistantOutput: content)
                    }
                }
                
                continuation.yield(content)
            }
            
            let functionCalls = llmStreamResults.values.compactMap { $0.functionCall }
            
            // Exit the while loop if we don't have any function calls
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
