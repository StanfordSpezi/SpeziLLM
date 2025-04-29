//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import os
@testable import Spezi
@testable import SpeziLLM
@testable import SpeziLLMOpenAI
import SwiftUI
import Testing

// To enable tests that require an OpenAI API key:
// Open the `SpeziLLM-Package.xctestplan` file and navigate to
// Configurations > Environment Variables. Add a new variable:
//
//   Name:  OPENAI_API_TOKEN
//   Value: your-secret-key-here
@Suite("LLM OpenAI Inference Tests (Using API Key)",
       .disabled(
           if: ProcessInfo.processInfo.environment["OPENAI_API_TOKEN"] == nil ||
           ProcessInfo.processInfo.environment["OPENAI_API_TOKEN"]?.isEmpty ?? true,
           "Skip test if no OPEN AI API Token is set as an environment variable"
       )
)
class LLMOpenAIInferenceTests {
    struct LLMOpenAITestFunction: LLMFunction {
        static let name: String = "perform_test"
        static let description: String = "Performs a tests and returns a specific value to ensure this function has been called"
        
                
        func execute() async throws -> String? {
            "The value to return to ensure the test was succesful is \"abcdefghijklmnopqrstuvwxyz\""
        }
    }
    
    static let logger = Logger(subsystem: "edu.stanford.spezi", category: "SpeziLLMInferenceTests")

    @MainActor
    internal func initTestLLMSession(_ schema: LLMOpenAISchema) throws -> LLMOpenAISession {
        let llmOpenAIPlatform = LLMOpenAIPlatform(configuration: LLMOpenAIPlatformConfiguration(apiToken: "mocked-token"))

        let runner = LLMRunner { llmOpenAIPlatform }
        try DependencyManager([runner]).resolve()
        runner.configure()

        return llmOpenAIPlatform.callAsFunction(with: schema)
    }


    @MainActor
    @Test
    func testOpenAIFunctionCalling() async throws {
        guard let openAIToken = ProcessInfo.processInfo.environment["OPENAI_API_TOKEN"] else {
            return
        }

        let schema = LLMOpenAISchema(
            parameters: .init(modelType: .gpt4o_mini, overwritingToken: openAIToken)
        ) {
            LLMOpenAITestFunction()
        }
        
        var context = LLMContext()
        context.append(userInput: "Hello! Return me the value needed for this test")
        
        let llmSession = try initTestLLMSession(schema)
        var oneShot = ""
        for try await stringPiece in try await llmSession.generate() {
            oneShot.append(stringPiece)
        }

        Self.logger.debug("""
                          LLMOpenAIInferenceTests: Received GPT response from OpenAI API call, during testOpenAIFunctionCalling()
                          Response: \(oneShot)
                          """)

        try #require(!oneShot.isEmpty)
        #expect(oneShot.contains("abcdefghijklmnopqrstuvwxyz"))
    }
}
