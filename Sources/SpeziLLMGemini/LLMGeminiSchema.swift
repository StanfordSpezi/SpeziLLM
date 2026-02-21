//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziLLMOpenAI


/// Defines the type and configuration of the ``LLMGeminiSession``.
///
/// The ``LLMGeminiSchema`` is used as a configuration for the to-be-used LLMGeminiPlatform LLM. It contains all information necessary for the creation of an executable ``LLMGeminiSession``.
/// It is bound to a ``LLMGeminiPlatform`` that is responsible for turning the ``LLMGeminiSchema`` to an ``LLMGeminiSession``.
///
/// - Tip: ``LLMGeminiSchema`` also enables the function calling mechanism to establish a structured, bidirectional, and reliable communication between the LLMGeminiPlatform LLMs and external tools. For details, refer to ``LLMFunction`` and ``LLMFunction/Parameter`` or the <doc:FunctionCalling> DocC article.
///
/// - Tip: For more information, refer to the documentation of the `LLMSchema` from SpeziLLM.
public typealias LLMGeminiSchema = LLMOpenAILikeSchema<LLMGeminiPlatformConfiguration>
