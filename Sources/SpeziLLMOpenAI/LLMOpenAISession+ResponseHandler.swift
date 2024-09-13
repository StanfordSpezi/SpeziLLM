//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

// OpenAI documentation: https://platform.openai.com/docs/guides/error-codes/api-errors

import OpenAPIRuntime

extension LLMOpenAISession {
    func handleErrorCode(_ statusCode: Int, prefix: String = "") {
        var prefix = prefix

        if prefix.isEmpty {
            prefix += " -"
        }

        switch statusCode {
        case 401:
            logger.error("SpeziLLMOpenAI:\(prefix) Invalid OpenAI API token")
        case 403:
            logger.error("SpeziLLMOpenAI:\(prefix) Model access check - Country, region, or territory not supported")
        case 429:
            logger.error("SpeziLLMOpenAI:\(prefix) Rate limit reached for requests")
        case 500:
            logger.error("SpeziLLMOpenAI:\(prefix) The server had an error while processing your request")
        case 503:
            logger.error("SpeziLLMOpenAI:\(prefix) The engine is currently overloaded, please try again later")
        default:
            logger.error("SpeziLLMOpenAI:\(prefix) Received unknown return code from OpenAI")
        }
    }
}
