//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


actor EventBroadcaster<Element: Sendable> {
    typealias Stream = AsyncThrowingStream<Element, any Error>

    private var listeners: [UUID: Stream.Continuation] = [:]

    /// Register and return a new stream for a listener
    func stream(
        bufferingPolicy: Stream.Continuation.BufferingPolicy = .unbounded
    ) -> Stream {
        let id = UUID()

        return Stream(bufferingPolicy: bufferingPolicy) { continuation in
            listeners[id] = continuation

            continuation.onTermination = { [weak self] _ in
                Task {
                    await self?.removeValue(for: id)
                }
            }
        }
    }

    /// Broadcast an element to everyone
    func broadcast(_ value: sending Element) {
        for continuation in listeners.values {
            continuation.yield(value)
        }
    }

    /// Finish stream, optionally with an error
    func finish(throwing error: (any Error)? = nil) {
        for continuation in listeners.values {
            if let error {
                continuation.finish(throwing: error)
            } else {
                continuation.finish()
            }
        }
        listeners.removeAll()
    }
    
    private func removeValue(for id: UUID) {
        self.listeners.removeValue(forKey: id)
    }
}
