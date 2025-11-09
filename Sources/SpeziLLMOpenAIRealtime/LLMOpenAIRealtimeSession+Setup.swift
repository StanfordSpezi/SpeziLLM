//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import GeneratedOpenAIClient
import OpenAPIURLSession
import os
import SpeziKeychainStorage
import SpeziLLM
import SpeziLLMOpenAI


extension LLMOpenAIRealtimeSession {
    /// Ensures the Realtime API session is set up and ready to use.
    ///
    /// If the session is already ready, it returns immediately.
    /// Otherwise, it initializes the connection and prepares the session for streaming.
    ///
    /// - Throws: An error if setup fails or if the operation is cancelled.
    @MainActor
    func ensureSetup() async throws {
        guard self.state != .ready && self.state != .generating else {
            return
        }

        try await setupSemaphore.waitCheckingCancellation()
        defer { setupSemaphore.signal() }

        if self.state == .ready || self.state == .generating {
            setupSemaphore.signal()
            return
        }

        try await self.setup()
    }
    
    /// Performs the initial setup by initializing the client and starting event listeners.
    ///
    /// - Throws: An error if client initialization fails.
    private func setup() async throws {
        Self.logger.debug("SpeziLLMOpenAIRealtime: OpenAI Realtime API is being initialized")
        await MainActor.run {
            self.state = .loading
        }

        try await self.initializeClient()

        await self.listenToLLMEvents()

        await MainActor.run {
            self.state = .ready
        }
        Self.logger.debug("SpeziLLMOpenAIRealtime: OpenAI Realtime API finished initializing, now ready to use")
    }

    /// Retrieves the auth token and opens the WebSocket connection to the Realtime API.
    ///
    /// - Throws: An error if the auth token is missing or the connection fails.
    private func initializeClient() async throws {
        let authToken = try await self.platform.configuration.authToken.getToken(keychainStorage: keychainStorage)

        guard let authToken = authToken else {
            Self.logger.error("LLMOpenAIRealtimeSession: Auth Token is nil")
            throw LLMOpenAIError.missingAPITokenInKeychain
        }

        do {
            try await apiConnection.open(token: authToken, schema: schema)
        } catch let error as any LLMError {
            Self.logger.error("SpeziLLMOpenAIRealtime: Encountered LLMError during initialization: \(error)")
            await apiConnection.cancel()
            await MainActor.run { self.state = .error(error: error) }
            throw error
        } catch {
            Self.logger.error("SpeziLLMOpenAIRealtime: Encountered unknown error during initialization: \(error)")
            await apiConnection.cancel()
            throw error
        }
    }
}
