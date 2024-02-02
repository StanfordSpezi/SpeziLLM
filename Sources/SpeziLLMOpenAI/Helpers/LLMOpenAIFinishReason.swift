//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// Represents possible OpenAI finish reasons in the inference response
/// More documentation can be found in the [OpenAI docs](https://platform.openai.com/docs/guides/text-generation/chat-completions-api)  <!-- markdown-link-check-disable-line -->
enum LLMOpenAIFinishReason: String, Decodable {
    case stop
    case length
    case functionCall = "function_call"
    case contentFilter = "content_filter"
    case null
}
