//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziLLMOpenAI


/// Represents an ``LLMAnthropicSchema`` in execution.
///
/// The ``LLMAnthropicSession`` is the executable version of the LLMAnthropicPlatform LLM containing context and state as defined by the ``LLMAnthropicSchema``.
/// It provides access to text-based models from Anthropic, such as Claude Opus or Sonnet.
///
/// The inference is started by ``LLMAnthropicSession/generate()``, returning an `AsyncThrowingStream` and can be cancelled via ``LLMAnthropicSession/cancel()``.
/// The ``LLMAnthropicSession`` exposes its current state via the ``LLMAnthropicSession/context`` property, containing all the conversational history with the LLM.
///
/// - Warning: The ``LLMAnthropicSession`` shouldn't be created manually but always through the ``LLMAnthropicPlatform`` via the `LLMRunner`.
///
/// - Tip: ``LLMAnthropicSession`` also enables the function calling mechanism to establish a structured, bidirectional, and reliable communication between the LLMAnthropicPlatform LLMs and external tools. For details, refer to ``LLMFunction`` and ``LLMFunction/Parameter`` or the <doc:FunctionCalling> DocC article.
///
/// - Tip: For more information, refer to the documentation of the `LLMSession` from SpeziLLM.
///
/// ### Usage
///
/// The example below demonstrates a minimal usage of the ``LLMAnthropicSession`` via the `LLMRunner`.
///
/// ```swift
/// import SpeziLLM
/// import SpeziLLMAnthropic
/// import SwiftUI
///
/// struct LLMAnthropicDemoView: View {
///     @Environment(LLMRunner.self) var runner
///     @State var responseText = ""
///
///     var body: some View {
///         Text(responseText)
///             .task {
///                 // Instantiate the `LLMAnthropicSchema` to an `LLMAnthropicSession` via the `LLMRunner`.
///                 let llmSession: LLMAnthropicSession = runner(
///                     with: LLMAnthropicSchema(
///                         parameters: .init(
///                             modelType: .gpt4o,
///                             systemPrompt: "You're a helpful assistant that answers questions from users.",
///                             overwritingToken: "abc123"
///                         )
///                     )
///                 )
///
///                 do {
///                     for try await token in try await llmSession.generate() {
///                         responseText.append(token)
///                     }
///                 } catch {
///                     // Handle errors here. E.g., you can use `ViewState` and `viewStateAlert` from SpeziViews.
///                 }
///             }
///     }
/// }
/// ```
public typealias LLMAnthropicSession = LLMOpenAILikeSession<LLMAnthropicPlatformConfiguration>
