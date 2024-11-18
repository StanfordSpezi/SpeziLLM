//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziLLM

public extension LLMContext {
    func formatForTransformersChat() -> [[String: String]] {
        self.map { entry in
            return [
                "role": entry.role.rawValue,
                "content": entry.content
            ]
        }
    }
}
