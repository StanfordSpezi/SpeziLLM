//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Foundation

public enum RealtimeLLMEvent: Sendable {
    case audioDelta(Data)
    case audioDone(Data)
    case userTranscriptDelta(String)
    case userTranscriptDone(String)
    case assistantTranscriptDelta(String)
    case assistantTranscriptDone(String)
    case toolCall(Data)
    case speechStarted
    case speechStopped
}
