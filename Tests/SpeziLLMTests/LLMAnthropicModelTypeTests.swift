//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
@testable import SpeziLLMAnthropic
import Testing


@Suite("LLM Anthropic ModelType")
struct LLMAnthropicModelTypeTests {
    @Test("Models map to the expected raw identifiers")
    func modelRawValues() {
        let expected: [(AnthropicPlatformDefinition.ModelType, String)] = [
            (.fable5, "claude-fable-5"),
            (.opus4_8, "claude-opus-4-8"),
            (.opus4_7, "claude-opus-4-7"),
            (.opus4_6, "claude-opus-4-6"),
            (.sonnet5, "claude-sonnet-5"),
            (.sonnet4_6, "claude-sonnet-4-6"),
            (.haiku4_5, "claude-haiku-4-5")
        ]

        for (model, rawValue) in expected {
            #expect(model.rawValue == rawValue)
        }
    }

    @Test("wellKnownModels lists every current model")
    func wellKnownModelsContainsCurrentModels() {
        let rawValues = Set(AnthropicPlatformDefinition.ModelType.wellKnownModels.map(\.rawValue))
        let models = [
            "claude-fable-5",
            "claude-opus-4-8", "claude-opus-4-7", "claude-opus-4-6",
            "claude-sonnet-5", "claude-sonnet-4-6",
            "claude-haiku-4-5"
        ]

        for model in models {
            #expect(rawValues.contains(model), "wellKnownModels is missing \(model)")
        }
    }

    @Test("wellKnownModels does not contain duplicate identifiers")
    func wellKnownModelsHasNoDuplicates() {
        let rawValues = AnthropicPlatformDefinition.ModelType.wellKnownModels.map(\.rawValue)
        #expect(rawValues.count == Set(rawValues).count)
    }

    @Test("The default model is the current flagship and is offered in the picker")
    func defaultModelIsSupported() {
        let defaultModel = AnthropicPlatformDefinition.ModelType.default
        #expect(defaultModel.rawValue == "claude-opus-4-8")
        #expect(AnthropicPlatformDefinition.ModelType.wellKnownModels.contains(defaultModel))
    }

    @Test("Arbitrary identifiers are accepted (open model set)")
    func arbitraryIdentifiersAreAccepted() {
        let viaRawValue = AnthropicPlatformDefinition.ModelType(rawValue: "some-future-model")
        let viaStringLiteral: AnthropicPlatformDefinition.ModelType = "some-future-model"
        #expect(viaRawValue == viaStringLiteral)
        #expect(viaRawValue.rawValue == "some-future-model")
    }

    @Test("ModelType survives a Codable round-trip")
    func modelTypeCodableRoundTrip() throws {
        let model = AnthropicPlatformDefinition.ModelType.opus4_8
        let encoded = try JSONEncoder().encode(model)
        let decoded = try JSONDecoder().decode(AnthropicPlatformDefinition.ModelType.self, from: encoded)
        #expect(decoded == model)
    }
}
