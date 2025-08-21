//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziLLM

protocol AudioCapableLLMSession: LLMSession {
    func listen() -> AsyncThrowingStream<Data, any Error>
    
    func appendUserAudio(_ buffer: Data) async throws
    
    func endUserTurn() async throws
    
    func events() async -> AsyncThrowingStream<RealtimeLLMEvent, any Error>
}
