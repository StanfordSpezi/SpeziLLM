//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import OpenAI


extension Chat {
    enum Allignment {
        case leading
        case trailing
    }
    
    
    var allignment: Allignment {
        switch self.role {
        case .user:
            return .trailing
        default:
            return .leading
        }
    }
}
