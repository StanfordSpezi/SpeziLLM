//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation

/// Describes possible states that the ``LLMSession`` can be in.
///
/// Based on the ``LLMState``, `SpeziLLM` performs proper actions on the model as well as state management.
public enum LLMState: CustomStringConvertible, Equatable, Sendable {
    /// The Spezi ``LLMSession`` is allocated, but the underlying model has not yet been initialized.
    case uninitialized
    /// The Spezi ``LLMSession`` is in the process of being initialized.
    case loading
    /// The Spezi ``LLMSession`` is initialized and ready for use.
    case ready
    /// The Spezi ``LLMSession`` is currently in the process of generating an output.
    case generating
    /// The Spezi ``LLMSession`` is currently executing function calls requested by the LLM.
    case callingTools
    /// The Spezi ``LLMSession`` is in an error state as described by the associated value ``LLMError``.
    case error(error: any LLMError)
    
    
    /// A textual description of the current ``LLMState``.
    public var description: String {
        switch self {
        case .uninitialized: String(localized: LocalizedStringResource("LLM_STATE_UNINITIALIZED", bundle: .atURL(from: .module)))
        case .loading: String(localized: LocalizedStringResource("LLM_STATE_LOADING", bundle: .atURL(from: .module)))
        case .ready: String(localized: LocalizedStringResource("LLM_STATE_READY", bundle: .atURL(from: .module)))
        case .generating: String(localized: LocalizedStringResource("LLM_STATE_GENERATING", bundle: .atURL(from: .module)))
        case .callingTools: String(localized: LocalizedStringResource("LLM_STATE_CALLING_TOOLS", bundle: .atURL(from: .module)))
        case .error: String(localized: LocalizedStringResource("LLM_STATE_ERROR", bundle: .atURL(from: .module)))
        }
    }
    
    
    /// Necessary `Equatable` implementation
    public static func == (lhs: LLMState, rhs: LLMState) -> Bool {
        switch (lhs, rhs) {
        case (.uninitialized, .uninitialized): true
        case (.loading, .loading): true
        case (.ready, .ready): true
        case (.generating, .generating): true
        case (.callingTools, .callingTools): true
        case (.error, .error): true
        default: false
        }
    }
}
