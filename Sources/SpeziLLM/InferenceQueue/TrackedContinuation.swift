//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Atomics

/// Tracks whether a continuation was cancelled.
@usableFromInline
package struct TrackedContinuation: Sendable {
    @usableFromInline let _cancelled = ManagedAtomic<Bool>(false)       // swiftlint:disable:this identifier_name

    /// True if the `AsyncStream/Continuation` has been cancelled
    @inlinable package var isCancelled: Bool {
        self._cancelled.load(ordering: .sequentiallyConsistent)
    }

    /// Inits a tracked continuation, without specifying a continuation yet.
    package init() {}

    /// Sets up the tracker to track a `AsyncStream/Continuation`
    @inlinable
    package func track<T>(_ continuation: AsyncStream<T>.Continuation) {
        continuation.onTermination = { @Sendable termination in
            switch termination {
            case .cancelled:
                print("123123: cancelled")
                self._cancelled.store(true, ordering: .sequentiallyConsistent)
            default:
                break
            }
        }
    }

    /// Sets up the tracker to track a `AsyncThrowingStream/Continuation`
    @inlinable
    package func track<T, E: Error>(_ continuation: AsyncThrowingStream<T, E>.Continuation) {
        continuation.onTermination = { @Sendable termination in
            switch termination {
            case .cancelled:
                print("123123: cancelled")
                self._cancelled.store(true, ordering: .sequentiallyConsistent)
            default:
                break
            }
        }
    }
}
