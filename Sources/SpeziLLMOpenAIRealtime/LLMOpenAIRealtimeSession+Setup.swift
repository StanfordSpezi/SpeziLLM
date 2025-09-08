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
    func ensureSetup() async throws -> Bool {
        let currentState = await self.state
        
        guard currentState != .ready && currentState != .generating else {
            return true
        }

        try await setupSemaphore.waitCheckingCancellation()

        let stateAfterSemaphore = await self.state
        if stateAfterSemaphore == .ready || stateAfterSemaphore == .generating {
            setupSemaphore.signal()
            return true
        }
        
        let setupResult = await self.setup()
        setupSemaphore.signal()
        
        print("ensureSetup: Done: setup was \(setupResult ? "successful" : "unsuccessful")!")

        return setupResult
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
            try await apiConnection.open(token: authToken, model: platform.configuration.model.rawValue)
            
            try await apiConnection.startEventLoop(platform: platform, schema: schema)
        } catch LLMOpenAIRealtimeConnection.RealtimeError.openAIError(let openAIError) {
            Self.logger.error("OpenAI Realtime init failed: \(openAIError)")
            await apiConnection.cancel()
            return false
        } catch {
            Self.logger.error("OpenAI Realtime init failed: \(error.localizedDescription)")
            await apiConnection.cancel()
            return false
        }
        
        return true
    }
}
