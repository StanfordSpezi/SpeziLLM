//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


enum FeatureFlags {
    /// Configures the local LLM to mock all generated responses in order to simplify development and write UI Tests.
    static let mockLocalLLM = ProcessInfo.processInfo.arguments.contains("--mockLocalLLM")
}
