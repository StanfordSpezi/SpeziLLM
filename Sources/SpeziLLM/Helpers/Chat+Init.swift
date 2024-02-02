//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziChat


extension Chat {
    public init(systemMessage: String) {
        self.init()
        self.append(
            .init(role: .system, content: systemMessage)
        )
    }
    
    public init(systemMessage: String, userInput: String) {
        self.init()
        self.append(
            .init(role: .system, content: systemMessage)
        )
        self.append(
            .init(role: .user, content: userInput)
        )
    }
}
