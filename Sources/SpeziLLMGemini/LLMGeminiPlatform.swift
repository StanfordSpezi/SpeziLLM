//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziLLMOpenAI


/// LLM execution platform of a ``LLMGeminiSchema``.
///
/// The ``LLMGeminiPlatform`` turns a received ``LLMGeminiSchema`` to an executable ``LLMGeminiSession``.
/// Use ``LLMGeminiPlatform/callAsFunction(with:)`` with an ``LLMGeminiSchema`` parameter to get an executable ``LLMGeminiSession`` that does the actual inference.
///
/// The platform can be configured with the ``LLMGeminiPlatformConfiguration``, enabling developers to specify properties like a custom server `URL`s, API tokens, the retry policy or timeouts.
///
/// - Important: ``LLMGeminiPlatform`` shouldn't be used directly but used via the `SpeziLLM` `LLMRunner` that delegates the requests towards the ``LLMGeminiPlatform``.
/// The `SpeziLLM` `LLMRunner` must be configured with the ``LLMGeminiPlatform`` within the Spezi `Configuration`.
///
/// - Tip: For more information, refer to the documentation of the `LLMPlatform` from SpeziLLM.
///
/// ### Usage
///
/// The example below demonstrates the setup of the ``LLMGeminiPlatform`` within the Spezi `Configuration`.
///
/// ```swift
/// class TestAppDelegate: SpeziAppDelegate {
///     override var configuration: Configuration {
///         Configuration {
///             LLMRunner {
///                 LLMGeminiPlatform()
///             }
///         }
///     }
/// }
/// ```
public typealias LLMGeminiPlatform = LLMOpenAILikePlatform<LLMGeminiPlatformConfiguration>
