//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziLLMOpenAI


/// Defines the type and configuration of the ``LLMAnthropicSession``.
///
/// The ``LLMAnthropicSchema`` is used as a configuration for the to-be-used LLMAnthropicPlatform LLM. It contains all information necessary for the creation of an executable ``LLMAnthropicSession``.
/// It is bound to a ``LLMAnthropicPlatform`` that is responsible for turning the ``LLMAnthropicSchema`` to an ``LLMAnthropicSession``.
///
/// - Note: This type behaves identical to SpeziLLMOpenAI's `LLMOpenAISchema`, except that it interacts with Anthropic's APIs instead of OpenAI's; see the [`LLMOpenAISchema`](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillmopenai/llmopenaischema) documentation for further documentation.
///
/// - Tip: ``LLMAnthropicSchema`` also enables the function calling mechanism to establish a structured, bidirectional, and reliable communication between the ``LLMAnthropicPlatform`` LLMs and external tools.
///     For more details, refer to the [`LLMOpenAISchema`](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillmopenai/llmopenaischema) documentation.
public typealias LLMAnthropicSchema = LLMOpenAILikeSchema<AnthropicPlatformDefinition>
