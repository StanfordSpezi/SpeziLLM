//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Spezi
import SwiftUI


/// A result builder used to aggregate multiple Spezi ``LLMPlatform``s within the ``LLMRunnerNew``.
@resultBuilder
@_documentation(visibility: internal)
public enum LLMRunnerPlatformBuilder: DependencyCollectionBuilder {
    /// An auto-closure expression, providing the default dependency value, building the ``DependencyCollection``.
    public static func buildExpression<L: LLMPlatform>(_ expression: @escaping @autoclosure () -> L) -> DependencyCollection {
        DependencyCollection(singleEntry: expression)
    }
}
