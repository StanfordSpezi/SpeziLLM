//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

extension LLMContext {
    /// Creates a new `Chat` array with an arbitrary number of system messages.
    ///
    /// - Parameters:
    ///    - systemMessages: `String`s that should be used as system messages.
    public init(systemMessages: [String]) {
        self = systemMessages.map { systemMessage in
            .init(role: .system, content: systemMessage)
        }
    }
    
    /// Resets the `Chat` array, deleting all persisted content.
    @MainActor
    public mutating func reset() {
        self = []
    }
}
