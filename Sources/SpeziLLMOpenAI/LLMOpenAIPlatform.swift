//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Semaphore
import Spezi
import SpeziLLM
import SpeziSecureStorage


public actor LLMOpenAIPlatform: LLMPlatform, DefaultInitializable {
    private let semaphore: AsyncSemaphore
    let configuration: LLMOpenAIPlatformConfiguration
    
    @MainActor public var state: LLMPlatformState = .idle
    @Dependency private var tokenSaver: LLMOpenAITokenSaver
    @Dependency private var secureStorage: SecureStorage
    
    
    public init(configuration: LLMOpenAIPlatformConfiguration) {
        self.configuration = configuration
        self.semaphore = AsyncSemaphore(value: configuration.concurrentStreams)
    }
    
    public init() {
        self.init(configuration: .init())
    }
    
    
    public nonisolated func configure() {
        Task {
            // If token passed via init
            if let apiToken = configuration.apiToken {
                try await secureStorage.store(
                    credentials: Credentials(username: LLMOpenAIConstants.credentialsUsername, password: apiToken),
                    server: LLMOpenAIConstants.credentialsServer
                )
            }
        }
    }
    
    public func callAsFunction(with llmSchema: LLMOpenAISchema) async -> LLMOpenAISession {
        LLMOpenAISession(self, schema: llmSchema, secureStorage: secureStorage)
    }
    
    func register() async throws {
        try await semaphore.waitUnlessCancelled()
        await MainActor.run {
            state = .processing
        }
    }
    
    func unregister() async {
        semaphore.signal()
        await MainActor.run {
            state = .idle
        }
    }
}
