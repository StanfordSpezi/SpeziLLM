//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


public actor LLMMockPlatform: LLMPlatform {
    @MainActor public let state: LLMPlatformState = .idle
    
    
    public init() {}
    
    
    public func callAsFunction(with: LLMMockSchema) async -> LLMMockSession {
        LLMMockSession(self, schema: with)
    }
}
