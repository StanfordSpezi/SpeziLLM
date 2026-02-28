//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziLLMOpenAI


/// Represents an ``LLMGeminiSchema`` in execution.
///
/// The ``LLMGeminiSession`` is the executable version of the LLMGeminiPlatform LLM containing context and state as defined by the ``LLMGeminiSchema``.
/// It provides access to text-based models from Gemini.
///
/// - Note: This type behaves identical to SpeziLLMOpenAI's `LLMGeminiSession`, except that it interacts with Gemini's APIs instead of OpenAI's; see the [`LLMOpenAISession`](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillmopenai/llmopenaisession) documentation for further documentation.
///
///
/// ### Usage
///
/// The example below demonstrates a minimal usage of the ``LLMGeminiSession`` via the `LLMRunner`.
///
/// ```swift
/// import SpeziLLM
/// import SpeziLLMGemini
/// import SwiftUI
///
/// struct LLMGeminiDemoView: View {
///     @Environment(LLMRunner.self) var runner
///     @State var responseText = ""
///
///     var body: some View {
///         Text(responseText)
///             .task {
///                 // Instantiate the `LLMGeminiSchema` to an `LLMGeminiSession` via the `LLMRunner`.
///                 let llmSession: LLMGeminiSession = runner(
///                     with: LLMGeminiSchema(
///                         parameters: .init(
///                             modelType: .gemini3_1_pro,
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
public typealias LLMGeminiSession = LLMOpenAILikeSession<GeminiPlatformDefinition>
