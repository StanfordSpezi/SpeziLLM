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
/// It provides access to text-based Gemini models.
///
/// The inference is started by ``LLMGeminiSession/generate()``, returning an `AsyncThrowingStream` and can be cancelled via ``LLMGeminiSession/cancel()``.
/// The ``LLMGeminiSession`` exposes its current state via the ``LLMGeminiSession/context`` property, containing all the conversational history with the LLM.
///
/// - Warning: The ``LLMGeminiSession`` shouldn't be created manually but always through the ``LLMGeminiPlatform`` via the `LLMRunner`.
///
/// - Tip: ``LLMGeminiSession`` also enables the function calling mechanism to establish a structured, bidirectional, and reliable communication between the LLMGeminiPlatform LLMs and external tools. For details, refer to ``LLMFunction`` and ``LLMFunction/Parameter`` or the <doc:FunctionCalling> DocC article.
///
/// - Tip: For more information, refer to the documentation of the `LLMSession` from SpeziLLM.
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
public typealias LLMGeminiSession = LLMOpenAILikeSession<GeminiPlatformDefinition>
