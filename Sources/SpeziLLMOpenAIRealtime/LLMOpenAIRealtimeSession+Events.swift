//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import GeneratedOpenAIClient
import SpeziLLM
import SpeziLLMOpenAI


extension LLMOpenAIRealtimeSession: FunctionCallLLMSession {
    @MainActor
    func listenToLLMEvents() { // swiftlint:disable:this cyclomatic_complexity
        Task { [weak self] in
            guard let eventStream = await self?.apiConnection.events() else {
                Self.logger.error("SpeziLLMOpenAIRealtime: No self in listenToLLMEvents...")
                return
            }

            do {
                for try await event in eventStream {
                    switch event {
                    case .assistantTranscriptDelta(let content):
                        self?.context.append(assistantOutput: content)
                    case .assistantTranscriptDone:
                        self?.context.completeAssistantStreaming()
                    case .userTranscriptDelta(let content):
                        self?.handleTranscript(itemId: content.itemId, content: content.delta, isComplete: false)
                    case .userTranscriptDone(let content):
                        self?.handleTranscript(itemId: content.itemId, content: "", isComplete: true)
                    case .speechStopped(let content):
                        self?.handleSpeechStopped(itemId: content.itemId)
                    case .functionCallRequested(let functionCall):
                        Task {
                            await self?.handleFunctionCall(functionCall: functionCall)
                        }
                    default:
                        break
                    }
                }
            } catch let error as any LLMError {
                Self.logger.error("SpeziLLMOpenAIRealtime: Encountered LLM Error: \(error)")
                self?.state = .error(error: error)
            } catch {
                Self.logger.error("SpeziLLMOpenAIRealtime: Encountered unknown error: \(error)")
            }
        }
    }
    
    /// Updates an existing context message by appending content, and optionally marking it as complete.
    ///
    /// If no message in the context has a UUID matching the deterministic UUID derived from `itemId`,
    /// this function does nothing and the content is ignored.
    @MainActor
    private func handleTranscript(itemId: String, content: String, isComplete: Bool) {
        let contentUUID = UUID.deterministic(from: itemId)
        let existingTranscriptIdx = self.context.firstIndex {
            $0.id == contentUUID
        }

        guard let existingTranscriptIdx = existingTranscriptIdx else {
            return
        }

        let existingMessage = self.context[existingTranscriptIdx]

        self.context[existingTranscriptIdx] = .init(
            role: .user,
            content: existingMessage.content + content,
            complete: isComplete,
            id: contentUUID,
            date: existingMessage.date
        )
    }
    
    /// When speech stops, directly append an empty user message to ensure it appears before any assistant
    /// messages in the context. This message then gets completed using the `.userTranscriptDelta` event
    ///
    /// - Note: If no transcription settings are configured inside the LLMSession's schema parameter, no message is appended to the context.
    @MainActor
    private func handleSpeechStopped(itemId: String) {
        guard self.schema.parameters.transcriptionSettings != nil else {
            return
        }

        let contentUUID = UUID.deterministic(from: itemId)
        self.context.append(
            .init(
                role: .user,
                content: "",
                complete: false,
                id: contentUUID,
                date: Date.now
            )
        )
    }
    
    @MainActor
    private func handleFunctionCall(functionCall: LLMOpenAIStreamResult.FunctionCall) async {
        typealias ConversationItemCreateEvent = Components.Schemas.RealtimeClientEventConversationItemCreate
        typealias RealtimeClientEventResponseCreate = Components.Schemas.RealtimeClientEventResponseCreate

        let functionCallResponse = try? await self.callFunction(
            availableFunctions: schema.functions,
            functionCallArgs: functionCall,
            failureHandling: .returnErrorInResponse
        )

        guard let functionCallResponse = functionCallResponse else {
            // Should never happen while having `failureHandling: .returnErrorInResponse`
            Self.logger.warning("LLMOpenAIRealtimeSession: callFunction() threw an error.")
            return
        }

        do {
            try await self.apiConnection.sendMessage(
                ConversationItemCreateEvent(
                    _type: .conversation_period_item_period_create,
                    item: .init(
                        _type: .function_call_output,
                        call_id: functionCallResponse.functionID,
                        output: functionCallResponse.response
                    )
                )
            )
            
            try await self.apiConnection.sendMessage(
                RealtimeClientEventResponseCreate(_type: .response_period_create)
            )
        } catch {
            Self.logger.error("LLMOpenAIRealtimeSession: Function call failed due to API connection")
        }
    }
}
