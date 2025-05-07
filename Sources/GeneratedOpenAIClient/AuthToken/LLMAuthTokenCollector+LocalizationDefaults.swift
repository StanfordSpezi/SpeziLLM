import SwiftUI


extension LLMAuthTokenCollector {
    @_documentation(visibility: internal)
    public enum Defaults {
        @_documentation(visibility: internal)
        public static let title = LocalizedStringResource(
            "LLM_AUTH_TOKEN_COLLECTOR_TITLE",
            bundle: .atURL(from: .module)
        )
        @_documentation(visibility: internal)
        public static let subtitle = LocalizedStringResource(
            "LLM_AUTH_TOKEN_COLLECTOR_SUBTITLE",
            bundle: .atURL(from: .module)
        )
        @_documentation(visibility: internal)
        public static let prompt = LocalizedStringResource(
            "LLM_AUTH_TOKEN_COLLECTOR_PROMPT",
            bundle: .atURL(from: .module)
        )
        @_documentation(visibility: internal)
        public static let hint = LocalizedStringResource(
            "LLM_AUTH_TOKEN_COLLECTOR_SUBTITLE_HINT",
            bundle: .atURL(from: .module)
        )
        @_documentation(visibility: internal)
        public static let action = LocalizedStringResource(
            "LLM_AUTH_TOKEN_COLLECTOR_SAVE_BUTTON",
            bundle: .atURL(from: .module)
        )
    }
}
