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
    func setup() async -> Bool {
        Self.logger.debug("SpeziLLMOpenAIRealtime: OpenAI Realtime API is being initialized")
        await MainActor.run {
            self.state = .loading
        }

        if !(await self.initializeClient()) {
            return false
        }

        await MainActor.run {
            self.state = .ready
        }
        Self.logger.debug("SpeziLLMOpenAIRealtime: OpenAI Realtime API finished initializing, now ready to use")
        return true
    }
    
    /// Initialize the OpenAI Realtime API client.
    ///
    /// - Returns: `true` if the client could be initialized, `false` otherwise.
    private func initializeClient() async -> Bool {
        let credentials = try? keychainStorage.retrieveCredentials(
            withUsername: LLMOpenAIConstants.credentialsUsername,
            for: .openAIKey
        )
        
        guard let openAPIKey = credentials?.password ?? platform.configuration.apiToken else {
            Self.logger.warning("Missing OpenAI key credentials or apiToken variable")
            return false
        }
        
        do {
            try await apiConnection.open(token: openAPIKey, model: "gpt-4o-mini-realtime-preview")
            
            try await apiConnection.startEventLoop()
        } catch {
            Self.logger.error("OpenAI Realtime init failed: \(error.localizedDescription)")
            await apiConnection.cancel()
            return false
        }
        
        return true
    }
}
