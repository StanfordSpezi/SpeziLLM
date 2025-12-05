//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


extension LLMAuthTokenCollector {
    /// Localization defaults of the ``LLMAuthTokenCollector``.
    @_documentation(visibility: internal)
    public enum Defaults {
        /// The defaults title of the ``LLMAuthTokenCollector``.
        @_documentation(visibility: internal) public static let title = LocalizedStringResource(
            "LLM_AUTH_TOKEN_COLLECTOR_TITLE",
            bundle: .atURL(from: .module)
        )
        /// The defaults subtitle of the ``LLMAuthTokenCollector``.
        @_documentation(visibility: internal) public static let subtitle = LocalizedStringResource(
            "LLM_AUTH_TOKEN_COLLECTOR_SUBTITLE",
            bundle: .atURL(from: .module)
        )
        /// The defaults prompt text of the ``LLMAuthTokenCollector``.
        @_documentation(visibility: internal) public static let prompt = LocalizedStringResource(
            "LLM_AUTH_TOKEN_COLLECTOR_PROMPT",
            bundle: .atURL(from: .module)
        )
        /// The defaults hint text of the ``LLMAuthTokenCollector``.
        @_documentation(visibility: internal) public static let hint = LocalizedStringResource(
            "LLM_AUTH_TOKEN_COLLECTOR_SUBTITLE_HINT",
            bundle: .atURL(from: .module)
        )
        /// The default action text of the ``LLMAuthTokenCollector``.
        @_documentation(visibility: internal) public static let action = LocalizedStringResource(
            "LLM_AUTH_TOKEN_COLLECTOR_SAVE_BUTTON",
            bundle: .atURL(from: .module)
        )
    }
}
