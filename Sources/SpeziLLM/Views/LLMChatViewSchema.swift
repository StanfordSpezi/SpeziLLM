//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziChat
import SwiftUI


/// Chat view that enables users to interact with an LLM based on an ``LLMSchema``.
///
/// The ``LLMChatViewSchema`` takes an ``LLMSchema`` instance as parameter within the ``LLMChatViewSchema/init(with:exportFormat:)``.
/// The ``LLMSchema`` defines the type and properties of the LLM that will be used by the ``LLMChatViewSchema`` to generate responses to user prompts.
///
/// - Tip: The ``LLMChatViewSchema`` is a convenience abstraction of the ``LLMChatView``. Refer to ``LLMChatView`` for more details.
///
/// - Tip: With the ``LLMChatViewSchema``, the developer doesn't have access to the underlying ``LLMSession`` that contains the ``LLMSession/context`` and ``LLMSession/state``. If access to these properties is required, please use the ``LLMChatView``.
///
/// ### Usage
///
/// An example usage of the ``LLMChatViewSchema`` with an ``LLMSchema`` can be seen in the following example.
/// The example uses the ``LLMMockSchema`` to generate responses to user prompts.
///
/// ```swift
/// struct LLMLocalChatSchemaView: View {
///     var body: some View {
///         LLMChatViewSchema(
///             with: LLMMockSchema()
///         )
///     }
/// }
/// ```
///
/// The ``LLMChatViewSchema`` may also be passed a `ChatView/ChatExportFormat` to enable the chat export functionality and define the format of the to-be-exported `SpeziChat/Chat`; possible export formats are `.pdf`, `.text`, and `.json`.
public struct LLMChatViewSchema<Schema: LLMSchema>: View {
    @LLMSessionProvider<Schema> var llm: Schema.Platform.Session
    private let exportFormat: ChatView.ChatExportFormat?
    
    
    public var body: some View {
        LLMChatView(session: $llm, exportFormat: exportFormat)
    }
    
    
    /// Creates a ``LLMChatViewSchema`` with an ``LLMSchema`` that provides developers with a basic chat view to interact with a Spezi LLM.
    /// 
    /// - Parameters:
    ///   - schema: The ``LLMSchema`` that defines the to-be-used LLM to generate outputs based on user input.
    ///   - exportFormat: An optional `ChatView/ChatExportFormat` to enable the chat export functionality and define the format of the to-be-exported `SpeziChat/Chat`.
    public init(
        with schema: Schema,
        exportFormat: ChatView.ChatExportFormat? = nil
    ) {
        self._llm = LLMSessionProvider(schema: schema)
        self.exportFormat = exportFormat
    }
}


#if DEBUG
#Preview {
    NavigationStack {
        LLMChatViewSchema(with: LLMMockSchema())
            .previewWith {
                LLMRunner {
                    LLMMockPlatform()
                }
            }
    }
}
#endif
