//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Atomics

/// A wrapper for a `AsyncThrowingStream/Continuation` that indicates if the continuation, and by extension the stream, is cancelled.
///
/// - Important: An orderly shutdown / termination of the `AsyncThrowingStream/Continuation` is not treated as a cancellation.
@usableFromInline
package struct ContinuationObserver<T: Sendable, E: Error>: Sendable {
    @usableFromInline let _cancelled = ManagedAtomic<Bool>(false)       // swiftlint:disable:this identifier_name
    @usableFromInline package let continuation: AsyncThrowingStream<T, E>.Continuation

    /// True if the `AsyncStream/Continuation` has been cancelled.
    @inlinable package var isCancelled: Bool {
        self._cancelled.load(ordering: .sequentiallyConsistent)
    }

    /// Inits a tracked continuation.
    /// 
    /// - Parameter continuation: The throwing continuation to track.
    package init(track continuation: AsyncThrowingStream<T, E>.Continuation) {
        self.continuation = continuation
        let cancelled = self._cancelled     // capture reference to atomic

        self.continuation.onTermination = { termination in
            switch termination {
            case .cancelled:
                cancelled.store(true, ordering: .sequentiallyConsistent)
            default:
                break
            }
        }
    }
}
