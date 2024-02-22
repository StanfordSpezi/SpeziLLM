//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


enum FeatureFlags: Sendable {
    /// Configures the LLMs to mock all generated responses in order to simplify development and write UI Tests.
    static let mockMode = ProcessInfo.processInfo.arguments.contains("--mockMode")
}
