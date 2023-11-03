//
// This source file is part of the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// A mock SpeziML ``LLM`` that is used for testing and preview purposes.
public actor LLMMock: LLM {
    public let type: LLMHostingType = .local
    public var state: LLMState = .uninitialized
    
    
    public init() {}
    
    
    public func setup(runnerConfig: LLMRunnerConfiguration) async throws {
        /// Set ``LLMState`` to ready
        self.state = .ready
    }
    
    public func generate(prompt: String, continuation: AsyncThrowingStream<String, Error>.Continuation) async {
        /// Generate mock message
        try? await Task.sleep(for: .seconds(1))
        continuation.yield("Mock ")
        try? await Task.sleep(for: .milliseconds(500))
        continuation.yield("Message ")
        try? await Task.sleep(for: .milliseconds(500))
        continuation.yield("from ")
        try? await Task.sleep(for: .milliseconds(500))
        continuation.yield("SpeziML!")
        continuation.finish()
    }
}