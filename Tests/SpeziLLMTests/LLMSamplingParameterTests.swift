//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

@testable import SpeziLLMAnthropic
@testable import SpeziLLMOpenAI
import Testing


@Suite("Sampling Parameters")
struct LLMSamplingParameterTests {
    @Test("A model that takes them is left alone")
    func keepsAcceptedParameters() {
        let parameters = LLMOpenAIModelParameters(temperature: 0, topP: 0.5, presencePenalty: 1)
        let accepted = parameters.accepted(by: AnthropicPlatformDefinition.ModelType.opus4_6)

        #expect(accepted.temperature == 0)
        #expect(accepted.topP == 0.5)
        #expect(accepted.presencePenalty == 1)
    }

    @Test("A model that refuses sampling has them dropped")
    func dropsRefusedParameters() {
        let parameters = LLMOpenAIModelParameters(
            temperature: 0.7,
            topP: 0.5,
            presencePenalty: 1,
            frequencyPenalty: 1,
            logitBias: ["1234": 50]
        )
        let accepted = parameters.accepted(by: AnthropicPlatformDefinition.ModelType.opus5)

        #expect(accepted.temperature == nil)
        #expect(accepted.topP == nil)
        #expect(accepted.presencePenalty == nil)
        #expect(accepted.frequencyPenalty == nil)
        #expect(accepted.logitBias.additionalProperties.isEmpty)
    }

    @Test("Parameters a model takes anyway survive a model that refuses sampling")
    func keepsUnrelatedParameters() {
        let parameters = LLMOpenAIModelParameters(
            temperature: 0.7,
            stopSequence: ["stop"],
            maxOutputLength: 512,
            seed: 42,
            user: "test-user"
        )
        let accepted = parameters.accepted(by: AnthropicPlatformDefinition.ModelType.opus5)

        #expect(accepted.maxOutputLength == 512)
        #expect(accepted.stopSequence == ["stop"])
        #expect(accepted.seed == 42)
        #expect(accepted.user == "test-user")
        #expect(accepted.temperature == nil)
    }

    @Test("A model that refuses sampling is untouched when none were requested")
    func leavesParametersAloneWhenNoneRequested() {
        let parameters = LLMOpenAIModelParameters(stopSequence: ["stop"], maxOutputLength: 512)
        let accepted = parameters.accepted(by: AnthropicPlatformDefinition.ModelType.opus5)

        #expect(accepted.maxOutputLength == 512)
        #expect(accepted.stopSequence == ["stop"])
        #expect(accepted.temperature == nil)
    }
}
