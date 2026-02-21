//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziLLMOpenAI


/// LLM execution platform of an Anthropic  ``LLMAnthropicSchema``.
///
/// The ``LLMAnthropicPlatform`` turns a received ``LLMAnthropicSchema`` to an executable ``LLMAnthropicSession``.
/// Use ``LLMAnthropicPlatform/callAsFunction(with:)`` with an ``LLMAnthropicSchema`` parameter to get an executable ``LLMAnthropicSession`` that does the actual inference.
///
/// The platform can be configured with the ``LLMAnthropicPlatformConfiguration``, enabling developers to specify properties like a custom server `URL`s, API tokens, the retry policy or timeouts.
///
/// - Important: ``LLMAnthropicPlatform`` shouldn't be used directly but used via the `SpeziLLM` `LLMRunner` that delegates the requests towards the ``LLMAnthropicPlatform``.
/// The `SpeziLLM` `LLMRunner` must be configured with the ``LLMAnthropicPlatform`` within the Spezi `Configuration`.
///
/// - Tip: For more information, refer to the documentation of the `LLMPlatform` from SpeziLLM.
///
/// ### Usage
///
/// The example below demonstrates the setup of the ``LLMAnthropicPlatform`` within the Spezi `Configuration`.
///
/// ```swift
/// class TestAppDelegate: SpeziAppDelegate {
///     override var configuration: Configuration {
///         Configuration {
///             LLMRunner {
///                 LLMAnthropicPlatform()
///             }
///         }
///     }
/// }
/// ```
public typealias LLMAnthropicPlatform = LLMOpenAILikePlatform<LLMAnthropicPlatformConfiguration>
