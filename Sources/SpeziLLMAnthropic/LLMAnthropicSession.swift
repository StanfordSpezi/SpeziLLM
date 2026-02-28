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
/// - Note: This type behaves identical to SpeziLLMOpenAI's `LLMAnthropicSession`, except that it interacts with Anthropic's APIs instead of OpenAI's; see the [`LLMOpenAISession`](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillmopenai/llmopenaisession) documentation for further documentation.
///
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
///                             modelType: .opus4_6,
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
public typealias LLMAnthropicSession = LLMOpenAILikeSession<AnthropicPlatformDefinition>
