//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Observation
import SpeziChat


@Observable
public class LLMMockSession: LLMSession {
    let platform: LLMMockPlatform
    let schema: LLMMockSchema
    private var task: Task<(), Never>?
    
    @MainActor public var state: LLMState = .uninitialized
    @MainActor public var context: Chat = []
    
    
    init(_ platform: LLMMockPlatform, schema: LLMMockSchema) {
        self.platform = platform
        self.schema = schema
    }
    
    @discardableResult
    public func generate() async throws -> AsyncThrowingStream<String, Error> {
        let (stream, continuation) = AsyncThrowingStream.makeStream(of: String.self)
        
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
            
            continuation.finish()
            await MainActor.run {
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
}
