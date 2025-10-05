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
    /// Set up the OpenAI Realtime API client.
    /// - Returns: `true` if the setup was successful, `false` otherwise.
    private func setup() async -> Bool {
        Self.logger.debug("SpeziLLMOpenAIRealtime: OpenAI Realtime API is being initialized")
        await MainActor.run {
            self.state = .loading
        }

        if !(await self.initializeClient()) {
            return false
        }

        await self.listenToLLMEvents()

        await MainActor.run {
            self.state = .ready
        }
        Self.logger.debug("SpeziLLMOpenAIRealtime: OpenAI Realtime API finished initializing, now ready to use")
        return true
    }

    @discardableResult
    @MainActor
    func ensureSetup() async throws -> Bool {
        guard self.state != .ready && self.state != .generating else {
            return true
        }

        do {
            try await setupSemaphore.waitCheckingCancellation()
        } catch {
            // Cancellation Error
            return false
        }
        defer { setupSemaphore.signal() }

        if self.state == .ready || self.state == .generating {
            setupSemaphore.signal()
            return true
        }
        
        return await self.setup()
    }
    
    /// Initialize the OpenAI Realtime API client.
    ///
    /// - Returns: `true` if the client could be initialized, `false` otherwise.
    private func initializeClient() async -> Bool {
        let authToken: String?
        do {
            authToken = try await self.platform.configuration.authToken.getToken(keychainStorage: keychainStorage)
        } catch {
            Self.logger.error("LLMOpenAIRealtimeSession: Failed to retrieve auth token: \(error.localizedDescription)")
            return false
        }
        
        guard let authToken = authToken else {
            Self.logger.error("LLMOpenAIRealtimeSession: Auth Token is nil")
            return false
        }

        do {
            try await apiConnection.open(token: authToken, schema: schema)
        } catch let error as any LLMError {
            Self.logger.error("SpeziLLMOpenAIRealtime: Encountered LLMError during initialization: \(error)")
            await apiConnection.cancel()
            await MainActor.run { self.state = .error(error: error) }
            return false
        } catch {
            Self.logger.error("SpeziLLMOpenAIRealtime: Encountered unknown error during initialization: \(error)")
            await apiConnection.cancel()
            return false
        }
        
        return true
    }
}
