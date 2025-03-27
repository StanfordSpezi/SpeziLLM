//
//  Test.swift
//  SpeziLLM
//
//  Created by Sébastien Letzelter on 27.03.25.
//

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
       .enabled(
           if: ProcessInfo.processInfo.environment["OPENAI_API_TOKEN"] != nil &&
               !(ProcessInfo.processInfo.environment["OPENAI_API_TOKEN"] ?? "").isEmpty,
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

    @MainActor
    @Test(
        .enabled(
            if: ProcessInfo.processInfo.environment["OPENAI_API_TOKEN"] != nil &&
                !(ProcessInfo.processInfo.environment["OPENAI_API_TOKEN"] ?? "").isEmpty,
            "Skip test if no OPEN AI API Token is set as an environment variable"
        )
    )
    func testOpenAIFunctionCalling() async throws {
        guard let openAIToken = ProcessInfo.processInfo.environment["OPENAI_API_TOKEN"] else {
            return
        }

        let llmOpenAIPlatform = LLMOpenAIPlatform(configuration: LLMOpenAIPlatformConfiguration(apiToken: openAIToken))
                                             
        let runner = LLMRunner { llmOpenAIPlatform }
        try DependencyManager([runner]).resolve()
        runner.configure()

        let schema = LLMOpenAISchema(
            parameters: .init(modelType: .gpt4o_mini, overwritingToken: openAIToken)
        ) {
            LLMOpenAITestFunction()
        }
        
        var context = LLMContext()
        context.append(userInput: "Hello! Return me the value needed for this test")

        let oneShot: String = try await runner.oneShot(with: schema, context: context)
        print(oneShot)

        try #require(!oneShot.isEmpty)
        #expect(oneShot.contains("abcdefghijklmnopqrstuvwxyz"))
    }

}
