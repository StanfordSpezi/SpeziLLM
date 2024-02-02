//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import llama
import Semaphore
import Spezi
import SpeziLLM


public actor LLMLocalPlatform: LLMPlatform, DefaultInitializable {
    // Enforce only one concurrent execution of a local LLM
    private let semaphore = AsyncSemaphore(value: 1)
    let configuration: LLMLocalPlatformConfiguration
    
    @MainActor public var state: LLMPlatformState = .idle
    
    
    public init(configuration: LLMLocalPlatformConfiguration) {
        self.configuration = configuration
    }
    
    public init() {
        self.init(configuration: .init())
    }
    
    
    public nonisolated func configure() {
        // Initialize the llama.cpp backend
        llama_backend_init(configuration.nonUniformMemoryAccess)
    }
    
    public func callAsFunction(with llmSchema: LLMLocalSchema) async -> LLMLocalSession {
        LLMLocalSession(self, schema: llmSchema)
    }
    
    nonisolated func register() async throws {
        try await semaphore.waitUnlessCancelled()
        await MainActor.run {
            state = .processing
        }
    }
    
    nonisolated func unregister() async {
        semaphore.signal()
        await MainActor.run {
            state = .idle
        }
    }
    
    
    deinit {
        // Frees the llama.cpp backend
        llama_backend_free()
    }
}
