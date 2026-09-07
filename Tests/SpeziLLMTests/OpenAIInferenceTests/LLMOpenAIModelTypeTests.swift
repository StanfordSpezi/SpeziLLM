//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
@testable import SpeziLLMOpenAI
import Testing


@Suite("LLM OpenAI ModelType")
struct LLMOpenAIModelTypeTests {
    /// Raw model identifiers OpenAI has retired or scheduled for shutdown.
    ///
    /// Referenced by raw value on purpose so the test target does not trigger deprecation warnings.
    private static let deprecatedRawValues: Set<String> = [
        "gpt-5-chat-latest",
        "gpt-5", "gpt-5-mini", "gpt-5-nano",
        "gpt-4-turbo", "gpt-4.1-nano",
        "o4-mini",
        "o3", "o3-pro", "o3-mini", "o3-mini-high",
        "o1-pro", "o1", "o1-mini",
        "gpt-3.5-turbo"
    ]


    @Test("Newly added models map to the expected raw identifiers")
    func newModelRawValues() {
        let expected: [(OpenAIPlatformDefinition.ModelType, String)] = [
            (.gpt6_astra, "gpt-6-astra"),
            (.gpt5_6, "gpt-5.6"),
            (.gpt5_6_sol, "gpt-5.6-sol"),
            (.gpt5_6_terra, "gpt-5.6-terra"),
            (.gpt5_6_luna, "gpt-5.6-luna"),
            (.gpt5_5, "gpt-5.5"),
            (.gpt5_5_pro, "gpt-5.5-pro"),
            (.gpt5_4, "gpt-5.4"),
            (.gpt5_4_pro, "gpt-5.4-pro"),
            (.gpt5_4_mini, "gpt-5.4-mini"),
            (.gpt5_4_nano, "gpt-5.4-nano")
        ]

        for (model, rawValue) in expected {
            #expect(model.rawValue == rawValue)
        }
    }

    @Test("wellKnownModels lists every newly added model")
    func wellKnownModelsContainsNewModels() {
        let rawValues = Set(OpenAIPlatformDefinition.ModelType.wellKnownModels.map(\.rawValue))
        let newModels = [
            "gpt-6-astra",
            "gpt-5.6", "gpt-5.6-sol", "gpt-5.6-terra", "gpt-5.6-luna",
            "gpt-5.5", "gpt-5.5-pro",
            "gpt-5.4", "gpt-5.4-pro", "gpt-5.4-mini", "gpt-5.4-nano"
        ]

        for model in newModels {
            #expect(rawValues.contains(model), "wellKnownModels is missing \(model)")
        }
    }

    @Test("wellKnownModels excludes deprecated and retired models")
    func wellKnownModelsExcludesDeprecatedModels() {
        let rawValues = Set(OpenAIPlatformDefinition.ModelType.wellKnownModels.map(\.rawValue))

        for deprecated in Self.deprecatedRawValues {
            #expect(!rawValues.contains(deprecated), "wellKnownModels should not offer the deprecated model \(deprecated)")
        }
    }

    @Test("wellKnownModels does not contain duplicate identifiers")
    func wellKnownModelsHasNoDuplicates() {
        let rawValues = OpenAIPlatformDefinition.ModelType.wellKnownModels.map(\.rawValue)
        #expect(rawValues.count == Set(rawValues).count)
    }

    @Test("The default model is supported and non-deprecated")
    func defaultModelIsSupported() {
        let defaultModel = OpenAIPlatformDefinition.ModelType.default
        #expect(defaultModel.rawValue == "gpt-5.6")
        #expect(OpenAIPlatformDefinition.ModelType.wellKnownModels.contains(defaultModel))
        #expect(!Self.deprecatedRawValues.contains(defaultModel.rawValue))
    }

    @Test("Deprecated models remain constructible for source compatibility")
    func deprecatedModelsRemainConstructible() {
        // Even though they are excluded from `wellKnownModels`, existing code passing these identifiers must keep working.
        for rawValue in Self.deprecatedRawValues {
            #expect(OpenAIPlatformDefinition.ModelType(rawValue: rawValue).rawValue == rawValue)
        }
    }

    @Test("Reasoning models are marked as refusing sampling parameters")
    func samplingParameterSupport() {
        for model in [OpenAIPlatformDefinition.ModelType.gpt6_astra, .gpt5_6, .gpt5_6_sol, .gpt5_5, .gpt5_4_mini] {
            #expect(!model.acceptsSamplingParameters, "\(model.rawValue) should refuse sampling parameters")
        }
        for rawValue in ["o1", "o3", "o4-mini"] {
            #expect(!OpenAIPlatformDefinition.ModelType(rawValue: rawValue).acceptsSamplingParameters)
        }
        for model in [OpenAIPlatformDefinition.ModelType.gpt4o, .gpt4o_mini, .gpt4_1, .gpt4_1_mini] {
            #expect(model.acceptsSamplingParameters, "\(model.rawValue) should still accept sampling parameters")
        }
        // The non-reasoning chat variant of its family kept them.
        #expect(OpenAIPlatformDefinition.ModelType(rawValue: "gpt-5-chat-latest").acceptsSamplingParameters)
    }

    @Test("Arbitrary identifiers are accepted (open model set)")
    func arbitraryIdentifiersAreAccepted() {
        let viaRawValue = OpenAIPlatformDefinition.ModelType(rawValue: "some-future-model")
        let viaStringLiteral: OpenAIPlatformDefinition.ModelType = "some-future-model"
        #expect(viaRawValue == viaStringLiteral)
        #expect(viaRawValue.rawValue == "some-future-model")
    }

    @Test("ModelType survives a Codable round-trip")
    func modelTypeCodableRoundTrip() throws {
        let model = OpenAIPlatformDefinition.ModelType.gpt5_6
        let encoded = try JSONEncoder().encode(model)
        let decoded = try JSONDecoder().decode(OpenAIPlatformDefinition.ModelType.self, from: encoded)
        #expect(decoded == model)
    }
}
