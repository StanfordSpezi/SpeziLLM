//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziLLMOpenAI


/// LLM execution platform of an Anthropic ``LLMAnthropicSchema``.
///
/// - Note: This type behaves identical to SpeziLLMOpenAI's `LLMOpenAIPlatform`, except that it interacts with Anthropic's APIs instead of OpenAI's; see the [`LLMOpenAIPlatform`](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillmopenai/llmopenaiplatform) documentation for further documentation.
///
/// ### Usage
///
/// The example below demonstrates the setup of the ``LLMAnthropicPlatform`` within the Spezi `Configuration`.
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
public typealias LLMAnthropicPlatform = LLMOpenAILikePlatform<AnthropicPlatformDefinition>
