//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziChat


/// A mock SpeziLLM ``LLM`` that is used for testing and preview purposes.
@Observable
public class LLMMock: LLM {
    public let type: LLMHostingType = .mock
    @MainActor public var state: LLMState = .uninitialized
    @MainActor public var context: Chat = []
    
    
    public init() {}
    
    
    public func setup(runnerConfig: LLMRunnerConfiguration) async throws {
        await MainActor.run {
            self.state = .ready
        }
    }
    
    public func generate(continuation: AsyncThrowingStream<String, Error>.Continuation) async {
        /// Generate mock message
        try? await Task.sleep(for: .seconds(1))
        continuation.yield("Mock ")
        try? await Task.sleep(for: .milliseconds(500))
        continuation.yield("Message ")
        try? await Task.sleep(for: .milliseconds(500))
        continuation.yield("from ")
        try? await Task.sleep(for: .milliseconds(500))
        continuation.yield("SpeziLLM!")
        continuation.finish()
    }
}
