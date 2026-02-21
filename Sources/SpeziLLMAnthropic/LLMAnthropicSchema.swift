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
/// - Tip: ``LLMAnthropicSchema`` also enables the function calling mechanism to establish a structured, bidirectional, and reliable communication between the LLMAnthropicPlatform LLMs and external tools. For details, refer to ``LLMFunction`` and ``LLMFunction/Parameter`` or the <doc:FunctionCalling> DocC article.
///
/// - Tip: For more information, refer to the documentation of the `LLMSchema` from SpeziLLM.
public typealias LLMAnthropicSchema = LLMOpenAILikeSchema<LLMAnthropicPlatformConfiguration>
