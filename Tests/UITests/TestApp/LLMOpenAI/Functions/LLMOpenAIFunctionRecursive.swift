//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziLLMOpenAI

/// A function that demonstrates recursive function calling behavior.
/// This function is designed to call itself repeatedly, which can help demonstrate
/// state transition issues in the LLM session when handling multiple function calls.
struct LLMOpenAIFunctionRecursive: LLMFunction {
    static let name: String = "recursive_call"
    static let description: String = "A function that can call itself repeatedly to demonstrate state transition issues"


    @Parameter(description: "Current number of times in the recursive iteration", minimum: 1.0, maximum: 3.0)
    var callCount: Double

    @Parameter(description: "Maximum number of times the function call should be called recursively", minimum: 1.0, maximum: 3.0)
    var maxCalls: Double

    @Parameter(description: "Optional message to include in the response")
    var message: String?


    func execute() async throws -> String? {
        let currentMessage = message ?? "Recursive call in progress"
        let response = """
        Recursive function called (count: \(callCount)/\(maxCalls))
        Message: \(currentMessage)
        """

        try await Task.sleep(nanoseconds: 2_000_000_000)

        if callCount < maxCalls {
            return """
            \(response)
            
            Please call the recursive_call function again with these parameters:
            - callCount: \(callCount + 1)
            - maxCalls: \(maxCalls)
            - message: "Continuing recursive chain - \(callCount + 1) of \(maxCalls)"
            """
        } else {
            return """
            \(response)
            
            Recursion complete! Reached maximum call count of \(maxCalls).
            """
        }
    }
}
