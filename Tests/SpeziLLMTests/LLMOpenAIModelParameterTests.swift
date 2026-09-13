//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

@testable import SpeziLLMOpenAI
import Testing


@Suite("LLM OpenAI Model Parameters")
struct LLMOpenAIModelParameterTests {
    /// Deprecated itself, so that using the retired initializer does not warn.
    @available(*, deprecated)
    private static func parametersWithSeed() -> LLMOpenAIModelParameters {
        LLMOpenAIModelParameters(temperature: 0.2, seed: 42, user: "spezi")
    }

    @Test("The response format is spelled the way the request takes it")
    func responseFormat() throws {
        #expect(LLMOpenAIModelParameters().responseFormat == nil)

        guard case .text = try #require(LLMOpenAIModelParameters(responseFormat: .text).responseFormat) else {
            Issue.record("Expected the text format")
            return
        }
        guard case .json_object = try #require(LLMOpenAIModelParameters(responseFormat: .jsonObject).responseFormat) else {
            Issue.record("Expected the JSON object format")
            return
        }
    }

    @Test("The retired seed initializer still compiles and keeps the other parameters")
    func retiredSeedInitializer() {
        let parameters = Self.parametersWithSeed()

        #expect(parameters.temperature == 0.2)
        #expect(parameters.user == "spezi")
    }
}
