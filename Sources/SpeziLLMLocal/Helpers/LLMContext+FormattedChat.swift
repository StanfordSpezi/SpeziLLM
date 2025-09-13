//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziLLM


extension LLMContext {
    /// Formats the current ``LLMContext`` for compatibility with Transformers-based chat models.
    ///
    /// - Returns: An array of dictionaries where each dictionary represents a message in the format:
    ///   - `role`: The role of the message (e.g., "user", "assistant"), derived from the `rawValue` of the entry's `role`.
    ///   - `content`: The textual content of the message.
    package var formattedChat: [[String: String]] {
        self.map { entry in
            [
                "role": entry.role.rawValue,
                "content": entry.content
            ]
        }
    }
}
