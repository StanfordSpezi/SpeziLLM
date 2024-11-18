//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


extension LLMContext {
    /// Append an ``LLMContextEntity/Role-swift.enum/assistant(toolCalls:)`` output (without `toolCalls`) to the ``LLMContext``.
    ///
    /// Automatically appends to the last ``LLMContextEntity/Role-swift.enum/assistant(toolCalls:)`` message if there is one, otherwise create a new one.
    /// If the `overwrite` parameter is `true`, the existing message is overwritten.
    ///
    /// - Parameters:
    ///    - output: The ``LLMContextEntity/Role-swift.enum/assistant(toolCalls:)`` output `String` (part) that should be appended. Can contain Markdown-formatted text.
    ///    - complete: Indicates if the ``LLMContextEntity`` is complete after appending to it one last time via the ``append(assistantOutput:complete:overwrite:)`` function.
    ///    - overwrite: Indicates if the already present content of the assistant message should be overwritten.
    @MainActor
    public mutating func append(assistantOutput output: String, complete: Bool = false, overwrite: Bool = false) {
        guard let lastContextEntity = self.last,
              case .assistant(let functionCalls) = lastContextEntity.role,
              functionCalls.isEmpty else {
            self.append(.init(role: .assistant(), content: output, complete: complete))
            return
        }
        
        self[self.count - 1] = .init(
            role: .assistant(),
            content: overwrite ? output : (lastContextEntity.content + output),
            complete: complete,
            id: lastContextEntity.id,
            date: lastContextEntity.date
        )
    }
    
    /// Append an ``LLMContextEntity/Role-swift.enum/user`` input to the ``LLMContext``.
    ///
    /// - Parameters:
    ///    - input: The ``LLMContextEntity/Role-swift.enum/user`` input that should be appended. Can contain Markdown-formatted text.
    @MainActor
    public mutating func append(userInput input: String, id: UUID = .init(), date: Date = .now) {
        self.append(.init(role: .user, content: input, id: id, date: date))
    }
    
    /// Append context to the input ``LLMContext`` as ``LLMContextEntity/Role-swift.enum/user``.
    ///
    /// - Parameters:
    ///    - input: The context for the prompt that should be appended.
    @MainActor
    public mutating func append(queryContext context: String, id: UUID = .init(), date: Date = .now) {
        let input = """
                    Context: 
                    \(context)
                    """
        
        self.append(.init(role: .user, content: input, id: id, date: date))
    }
    
    /// Append a ``LLMContextEntity/Role-swift.enum/system`` prompt to the ``LLMContext``.
    ///
    /// - Parameters:
    ///    - systemPrompt: The ``LLMContextEntity/Role-swift.enum/system`` prompt of the ``LLMContext``, inserted at the very beginning. Can contain Markdown-formatted text.
    ///    - insertAtStart: Defines if the system prompt should be inserted at the start of the conversational context, defaults to `true`.
    @MainActor
    public mutating func append(systemMessage systemPrompt: String, insertAtStart: Bool = true) {
        if insertAtStart {
            if let index = self.lastIndex(where: { $0.role == .system }) {
                // Insert new system prompt after the existing ones
                self.insert(.init(role: .system, content: systemPrompt), at: index + 1)
            } else {
                // If no system prompt exists yet, insert at the very beginning
                self.insert(.init(role: .system, content: systemPrompt), at: 0)
            }
        } else {
            self.append(.init(role: .system, content: systemPrompt))
        }
    }
    
    /// Append a ``LLMContextEntity/Role-swift.enum/tool(id:name:)`` response from a function call to the ``LLMContext``.
    ///
    /// - Parameters:
    ///    - functionName: The name of the ``LLMContextEntity/Role-swift.enum/tool(id:name:)`` that is called by the LLM.
    ///    - functionResponse: The response `String` of the ``LLMContextEntity/Role-swift.enum/tool(id:name:)`` that is called by the LLM.
    @MainActor
    public mutating func append(forFunction functionName: String, withID functionID: String, response functionResponse: String) {
        self.append(.init(role: .tool(id: functionID, name: functionName), content: functionResponse))
    }
    
    /// Append an ``LLMContextEntity/Role-swift.enum/assistant(toolCalls:)`` response including `toolCalls` to the ``LLMContext``.
    ///
    /// - Parameters:
    ///    - functionCalls: The function calls (tool calls) that the LLM requested.
    @MainActor
    public mutating func append(functionCalls: [LLMContextEntity.ToolCall]) {
        self.append(.init(role: .assistant(toolCalls: functionCalls), content: ""))
    }
    
    /// Marks the latest chat entry as ``LLMContextEntity/complete``, if the role of the chat is ``LLMContextEntity/Role-swift.enum/assistant(toolCalls:)`` without any `toolCalls`.
    @MainActor
    public mutating func completeAssistantStreaming() {
        guard let lastContextEntity = self.last,
              case .assistant(let functionCalls) = lastContextEntity.role,
              functionCalls.isEmpty else {
            return
        }
        
        self[self.count - 1] = .init(
            role: .assistant(),
            content: lastContextEntity.content,
            complete: true,
            id: lastContextEntity.id,
            date: lastContextEntity.date
        )
    }
}
