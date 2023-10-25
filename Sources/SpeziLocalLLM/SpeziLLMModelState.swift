//
// This source file is part of the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation


public enum SpeziLLMModelState: CustomStringConvertible, Equatable {
    case idle
    case loading
    case ready
    case inferring
    case error(error: SpeziLLMError)
    
    
    public var description: String {
        switch self {
        case .idle: "idle"
        case .loading: "loading"
        case .ready: "ready"
        case .inferring: "inferring"
        case .error: "error"
        }
    }
}
