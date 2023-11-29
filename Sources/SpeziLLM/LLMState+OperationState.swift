//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziViews

// Needs to be in a separate file as an extension in the file of the ``LLMState`` will lead to
// the "Circular reference resolving attached macro 'Observable'" error during compiling (see https://github.com/apple/swift/issues/66450)
/// Maps the ``LLMState`` to the SpeziViews `ViewState` via the conformance to the SpeziViews `OperationState` protocol.
extension LLMState: OperationState {
    public var representation: ViewState {
        switch self {
        case .uninitialized, .ready:
            .idle
        case .generating, .loading:
            .processing
        case .error(let error):
            .error(error)
        }
    }
}
