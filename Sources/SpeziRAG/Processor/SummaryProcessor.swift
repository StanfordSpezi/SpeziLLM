//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Spezi
import SpeziLLM
import SpeziLLMLocal


public class SummaryProcessor {
    public enum Defaults {
        public static var llmSchema: LLMLocalSchema {
            .init(model: .custom(id: "mlx-community/Llama-3.2-1B-Instruct-4bit"))
        }
    }
    
    private let llmRunner: LLMRunner
    private let summaryLLMSchema: any LLMSchema
    
    public init(on runner: LLMRunner, schema: any LLMSchema = Defaults.llmSchema) {
        self.llmRunner = runner
        self.summaryLLMSchema = schema
    }
    
    public func process(prompt: String) async throws -> String {
        try await llmRunner.oneShot(
            with: summaryLLMSchema,
            context: [.init(role: .system, content: prompt)]
        )
    }
}
