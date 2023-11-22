//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation

/// The ``LLMState`` describes possible states that the LLM can be in.
/// Based on the ``LLMState``, `SpeziLLM` performs proper actions on the model as well as state management.
public enum LLMState: CustomStringConvertible, Equatable {
    /// The Spezi ``LLM`` is allocated, but the underlying llama.cpp model has not yet been initialized.
    case uninitialized
    /// The Spezi ``LLM`` is in the process of being initialized, so the model file is loaded from memory.
    case loading
    /// The Spezi ``LLM`` as well as the underlying llama.cpp model is initialized and ready for use.
    case ready
    /// The Spezi ``LLM`` is currently in the process of generating an output.
    case generating
    /// The Spezi ``LLM`` is in an error state as described by the associated value ``LLMError``.
    case error(error: LLMError)
    
    
    /// A textual description of the current ``LLMState``.
    public var description: String {
        switch self {
        case .uninitialized: String(localized: LocalizedStringResource("LLM_STATE_UNINITIALIZED", bundle: .atURL(from: .module)))
        case .loading: String(localized: LocalizedStringResource("LLM_STATE_LOADING", bundle: .atURL(from: .module)))
        case .ready: String(localized: LocalizedStringResource("LLM_STATE_READY", bundle: .atURL(from: .module)))
        case .generating: String(localized: LocalizedStringResource("LLM_STATE_GENERATING", bundle: .atURL(from: .module)))
        case .error: String(localized: LocalizedStringResource("LLM_STATE_ERROR", bundle: .atURL(from: .module)))
        }
    }
}
