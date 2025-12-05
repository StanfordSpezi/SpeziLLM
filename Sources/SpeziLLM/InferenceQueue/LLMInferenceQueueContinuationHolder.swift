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
import SpeziFoundation

/// Holds the continuations of the inference tasks of a certain ``LLMPlatform`` with the ability to finish/cancel them.
package final class LLMInferenceQueueContinuationHolder: Sendable {
    private let lock: RWLock = .init()
    // protected by the lock above
    nonisolated(unsafe) private var continuations: [UUID: AsyncThrowingStream<String, any Error>.Continuation] = [:]

    package init() {}

    /// Temporarily retains a stream continuation while executing an asynchronous block.
    ///
    /// - Parameters:
    ///   - continuation: The `AsyncThrowingStream<String, Error>.Continuation` to hold.
    ///   - handle: An asynchronous closure during which the continuation remains stored.
    ///
    /// - Note: The continuation is added to the holder before `handle` runs and removed afterward. Removal does not cancel the continuation.
    package func withContinuationHold(
        continuation: AsyncThrowingStream<String, any Error>.Continuation,
        handle: () async -> Void
    ) async {
        // store the continuation so that we can cancel it later
        let id = self.add(continuation)

        await handle()

        // remove continuation from holder (does not cancel it)
        self.remove(id: id)
    }

    /// Adds a new continuation to the holder.
    /// - Parameter continuation: The stream continuation to add.
    /// - Returns: The unique ID associated with this continuation.
    package func add(_ continuation: AsyncThrowingStream<String, any Error>.Continuation) -> UUID {
        self.lock.withWriteLock {
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
        guard (self.lock.withWriteLock { self.continuations.removeValue(forKey: id) }) != nil else {
            return false
        }

        return true
    }

    /// Cancels all stored continuations by finishing them with a `CancellationError`.
    /// After this call, the holder is emptied.
    package func cancelAll() {
        self.lock.withWriteLock {
            self.continuations.forEach { continuation in
                continuation.value.finish(throwing: CancellationError())
            }
            self.continuations.removeAll()
        }
    }
}
