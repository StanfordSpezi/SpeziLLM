//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Observation
import SpeziLLM


/// A mock ``LLMLocalMockSession``, used for testing purposes.
///
/// See `LLMMockSession` for more details
@Observable
public final class LLMLocalMockSession: LLMSession, @unchecked Sendable {
    let platform: LLMLocalPlatform
    let schema: LLMLocalSchema
    
    @ObservationIgnored private var task: Task<(), Never>?
    
    @MainActor public var state: LLMState = .uninitialized
    @MainActor public var context: LLMContext = []
    
    
    /// Initializer for the ``LLMMockSession``.
    ///
    /// - Parameters:
    ///     - platform: The mock LLM platform.
    ///     - schema: The mock LLM schema.
    init(_ platform: LLMLocalPlatform, schema: LLMLocalSchema) {
        self.platform = platform
        self.schema = schema
    }
    
    
    @discardableResult
    public func generate() async throws -> AsyncThrowingStream<String, Error> {
        let (stream, continuation) = AsyncThrowingStream.makeStream(of: String.self)
        
        // swiftlint:disable:next closure_body_length
        task = Task {
            await MainActor.run {
                self.state = .loading
            }
            try? await Task.sleep(for: .seconds(1))
            guard await !checkCancellation(on: continuation) else {
                return
            }
            
            /// Generate mock messages
            await MainActor.run {
                self.state = .generating
            }
            await injectAndYield("Mock ", on: continuation)
            
            try? await Task.sleep(for: .milliseconds(500))
            guard await !checkCancellation(on: continuation) else {
                return
            }
            await injectAndYield("Message ", on: continuation)
            
            try? await Task.sleep(for: .milliseconds(500))
            guard await !checkCancellation(on: continuation) else {
                return
            }
            await injectAndYield("from ", on: continuation)
            
            try? await Task.sleep(for: .milliseconds(500))
            guard await !checkCancellation(on: continuation) else {
                return
            }
            await injectAndYield("SpeziLLM!", on: continuation)
            
            try? await Task.sleep(for: .milliseconds(500))
            guard await !checkCancellation(on: continuation) else {
                return
            }
            await injectAndYield("Using SpeziLLMLocal only works on physical devices.", on: continuation)
            
            
            continuation.finish()
            await MainActor.run {
                context.completeAssistantStreaming()
                self.state = .ready
            }
        }
        
        return stream
    }
    
    public func cancel() {
        task?.cancel()
    }
    
    private func injectAndYield(_ piece: String, on continuation: AsyncThrowingStream<String, Error>.Continuation) async {
        continuation.yield(piece)
        if schema.injectIntoContext {
            await MainActor.run {
                context.append(assistantOutput: piece)
            }
        }
    }
    
    
    deinit {
        cancel()
    }
}
