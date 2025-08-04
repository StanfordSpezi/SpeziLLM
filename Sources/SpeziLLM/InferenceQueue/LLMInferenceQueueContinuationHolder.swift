//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Holds the continuations of the inference tasks of a certain ``LLMPlatform`` with the ability to finish/cancel them.
package final class LLMInferenceQueueContinuationHolder: Sendable {
    private let lock: NSLock = .init()
    // protected by the lock above
    nonisolated(unsafe) private var continuations: [UUID: AsyncThrowingStream<String, any Error>.Continuation] = [:]

    package init() {}

    /// Adds a new continuation to the holder.
    /// - Parameter continuation: The stream continuation to add.
    /// - Returns: The unique ID associated with this continuation.
    package func add(_ continuation: AsyncThrowingStream<String, any Error>.Continuation) -> UUID {
        self.lock.withLock {
            let uuid = UUID()
            self.continuations[uuid] = continuation
            return uuid
        }
    }

    /// Removes the continuation associated with the given ID.
    /// - Parameter id: The UUID key for the continuation to remove.
    /// - Returns: `true` if a continuation was found and cancelled; otherwise `false`.
    @discardableResult
    package func remove(id: UUID) -> Bool {
        guard self.lock.withLock({ self.continuations.removeValue(forKey: id) }) != nil else {
            return false
        }

        return true
    }

    /// Cancels all stored continuations by finishing them with a `CancellationError`.
    /// After this call, the holder is emptied.
    package func cancelAll() {
        self.lock.withLock {
            self.continuations.forEach { continuation in
                continuation.value.finish(throwing: CancellationError())
            }
            self.continuations.removeAll()
        }
    }
}
