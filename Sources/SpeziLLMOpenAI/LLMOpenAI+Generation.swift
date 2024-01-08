//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import OpenAI
import SpeziChat


extension LLMOpenAI {
    func _generate(continuation: AsyncThrowingStream<String, Error>.Continuation) async throws {    // swiftlint:disable:this identifier_name
        while true {
            let chatStream: AsyncThrowingStream<ChatStreamResult, Error> = await self.model.chatsStream(query: self.openAIChatQuery)
            
            //let currentMessageCount = await self.context.count
            var llmStreamResults: [LLMStreamResult] = []
            
            for try await chatStreamResult in chatStream {
                // Parse the different elements in mutable llm stream results.
                for choice in chatStreamResult.choices {
                    let existingLLMStreamResult = llmStreamResults.first(where: { $0.id == choice.index })
                    let llmStreamResult: LLMStreamResult
                    
                    if let existingLLMStreamResult {
                        llmStreamResult = existingLLMStreamResult
                    } else {
                        llmStreamResult = LLMStreamResult(id: choice.index)
                        llmStreamResults.append(llmStreamResult)
                    }
                    
                    llmStreamResult.append(choice: choice)
                }
                
                // Append assistant messages during the streaming to ensure that they are presented in the UI.
                // Limitation: We currently don't really handle multiple llmStreamResults, messages could overwritten.
                for llmStreamResult in llmStreamResults where llmStreamResult.role == .assistant && !(llmStreamResult.content?.isEmpty ?? true) {
                    // TODO: Is this really equivalent?!
                    /*
                    let newMessage = SpeziChat.ChatEntity(
                        role: .assistant,
                        content: llmStreamResult.content ?? ""
                    )
                    
                    if await self.context.indices.contains(currentMessageCount) {
                        self.context[currentMessageCount] = newMessage
                    } else {
                        self.context.append(newMessage)
                    }
                     */
                    
                    await MainActor.run {
                        self.context.append(assistantOutput: llmStreamResult.content ?? "")
                    }
                }
            }
            
            let functionCalls = llmStreamResults.compactMap { $0.functionCall }
            
            // Exit the while loop if we don't have any function calls.
            guard !functionCalls.isEmpty else {
                break
            }
            
            for functionCall in functionCalls {
                print("Function Call - Name: \(functionCall.name ?? ""), Arguments: \(functionCall.arguments ?? "")")   // TODO: Logger
                
                guard let functionName = functionCall.name,
                      let functionArgument = functionCall.arguments?.data(using: .utf8),
                      let function = self.functions[functionName] else {
                    print("Couldn't find the requested function or arguments from the LLM!") // TODO: Logger
                    return
                }
                
                // Inject parameters into the @Parameters of the function call
                try function.injectParameterValues(from: functionArgument)
                
                // Execute function
                let functionCallResponse = try await function.execute()
                await MainActor.run {
                    self.context.append(forFunction: functionName, response: functionCallResponse)
                }
            }
        }
    }
}
