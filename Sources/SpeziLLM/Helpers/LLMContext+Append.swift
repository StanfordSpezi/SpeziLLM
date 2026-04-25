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
    /// When continuing an existing assistant entity, that entity's `interactionId` is preserved; the
    /// `interactionId` parameter is only used when creating a new entity.
    ///
    /// - Parameters:
    ///    - output: The ``LLMContextEntity/Role-swift.enum/assistant(toolCalls:)`` output `String` (part) that should be appended. Can contain Markdown-formatted text.
    ///    - complete: Indicates if the ``LLMContextEntity`` is complete after appending to it one last time via the ``append(assistantOutput:complete:overwrite:)`` function.
    ///    - overwrite: Indicates if the already present content of the assistant message should be overwritten.
    ///    - interactionId: The interaction this output belongs to. Used when creating a new entity.
    @MainActor
    public mutating func append(
        assistantOutput output: String,
        complete: Bool = false,
        overwrite: Bool = false,
        interactionId: LLMInteractionId? = nil
    ) {
        guard let lastContextEntity = self.last,
              case .assistant(let functionCalls) = lastContextEntity.role,
              functionCalls.isEmpty else {
            self.append(.init(role: .assistant(), content: output, complete: complete, interactionId: interactionId))
            return
        }

        self[self.count - 1] = .init(
            role: .assistant(),
            content: overwrite ? output : (lastContextEntity.content + output),
            complete: complete,
            id: lastContextEntity.id,
            date: lastContextEntity.date,
            interactionId: lastContextEntity.interactionId
        )
    }

    /// Append an ``LLMContextEntity/Role-swift.enum/user`` input to the ``LLMContext``.
    ///
    /// - Parameters:
    ///    - input: The ``LLMContextEntity/Role-swift.enum/user`` input that should be appended. Can contain Markdown-formatted text.
    ///    - id: A unique identifier of the ``LLMContextEntity``.
    ///    - date: The `Date` of the ``LLMContextEntity``.
    ///    - interactionId: The interaction this user input belongs to. Defaults to `nil`; sessions typically tag the user message retroactively when the matching response begins.
    @MainActor
    public mutating func append(
        userInput input: String,
        id: UUID = .init(),
        date: Date = .now,
        interactionId: LLMInteractionId? = nil
    ) {
        self.append(.init(role: .user, content: input, id: id, date: date, interactionId: interactionId))
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
    ///    - functionID: The id of the ``LLMContextEntity``.
    ///    - functionResponse: The response `String` of the ``LLMContextEntity/Role-swift.enum/tool(id:name:)`` that is called by the LLM.
    ///    - interactionId: The interaction this tool result belongs to.
    @MainActor
    public mutating func append(
        forFunction functionName: String,
        withID functionID: String,
        response functionResponse: String,
        interactionId: LLMInteractionId? = nil
    ) {
        self.append(.init(
            role: .tool(id: functionID, name: functionName),
            content: functionResponse,
            interactionId: interactionId
        ))
    }

    /// Append an ``LLMContextEntity/Role-swift.enum/assistant(toolCalls:)`` response including `toolCalls` to the ``LLMContext``.
    ///
    /// - Parameters:
    ///    - functionCalls: The function calls (tool calls) that the LLM requested.
    ///    - interactionId: The interaction these tool calls belong to.
    @MainActor
    public mutating func append(
        functionCalls: [LLMContextEntity.ToolCall],
        interactionId: LLMInteractionId? = nil
    ) {
        self.append(.init(
            role: .assistant(toolCalls: functionCalls),
            content: "",
            interactionId: interactionId
        ))
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
            date: lastContextEntity.date,
            interactionId: lastContextEntity.interactionId
        )
    }

    /// Append a delta to the latest ``LLMContextEntity/Role-swift.enum/assistantThinking`` entry, or start a new one.
    ///
    /// Use ``beginAssistantThinkingPlaceholder(interactionId:)`` to mark the boundary between reasoning summary parts;
    /// this method then appends incoming deltas onto the active thinking entity.
    ///
    /// When continuing an existing thinking entity, that entity's `interactionId` is preserved; the
    /// `interactionId` parameter is only used when creating a new entity.
    ///
    /// - Parameters:
    ///    - thinking: The reasoning text delta to append. Can contain Markdown.
    ///    - complete: Indicates if the entity is complete after this append.
    ///    - interactionId: The interaction this delta belongs to. Used when creating a new entity.
    @MainActor
    public mutating func append(
        assistantThinking thinking: String,
        complete: Bool = false,
        interactionId: LLMInteractionId? = nil
    ) {
        if let last, last.role == .assistantThinking {
            self[endIndex - 1].content += thinking
            self[endIndex - 1].complete = complete
        } else {
            self.append(.init(role: .assistantThinking, content: thinking, complete: complete, interactionId: interactionId))
        }
    }

    /// Marks the latest chat entry as ``LLMContextEntity/complete``, if its role is ``LLMContextEntity/Role-swift.enum/assistantThinking``.
    @MainActor
    public mutating func completeAssistantThinkingStreaming() {
        if let last, last.role == .assistantThinking {
            self[endIndex - 1].complete = true
        }
    }

    /// Ensures there is an in-progress ``LLMContextEntity/Role-swift.enum/assistantThinking`` entity at the end of the context.
    ///
    /// Sessions call this to signal that the model is doing work that hasn't yet produced visible output —
    /// e.g. while waiting for a reasoning model to finish its internal thinking phase. The entity's
    /// ``LLMContextEntity/date`` doubles as the start timestamp (useful for displaying elapsed time in the UI).
    ///
    /// Idempotent: if the latest entity is already an incomplete thinking entity, this is a no-op so
    /// existing content (e.g. a partially streamed reasoning summary) is preserved.
    ///
    /// - Parameter interactionId: The interaction this thinking phase belongs to. Used when creating a new entity.
    @MainActor
    public mutating func beginAssistantThinkingPlaceholder(interactionId: LLMInteractionId? = nil) {
        if let last = self.last, case .assistantThinking = last.role, !last.complete {
            return
        }
        self.append(.init(role: .assistantThinking, content: "", complete: false, interactionId: interactionId))
    }

    /// Removes the trailing ``LLMContextEntity/Role-swift.enum/assistantThinking`` entity if it is still in-progress.
    ///
    /// Sessions call this on cancel or error paths to clean up an unfinished thinking placeholder so it
    /// doesn't linger in the conversation history.
    @MainActor
    public mutating func removeIncompleteAssistantThinking() {
        guard let last = self.last, case .assistantThinking = last.role, !last.complete else {
            return
        }
        self.removeLast()
    }

    /// The start of the currently-active thinking phase, or `nil` if the latest entity isn't an in-progress thinking entity.
    ///
    /// "Active" means the latest entity is an incomplete `.assistantThinking`. The returned date is the
    /// `date` of the *earliest* entity that shares the active entity's ``LLMContextEntity/interactionId``,
    /// so the timer reflects elapsed time for the entire user → LLM turn — not just the current sub-step
    /// between function calls. If the active thinking entity has no interaction ID, falls back to that
    /// entity's own date.
    ///
    /// View code can show "Thinking… (Xs)" with `Date.now.timeIntervalSince(value)`.
    public var currentThinkingStart: Date? {
        guard let last = self.last,
              case .assistantThinking = last.role,
              !last.complete else {
            return nil
        }
        guard let id = last.interactionId else {
            return last.date
        }
        return self.first(where: { $0.interactionId == id })?.date ?? last.date
    }
    
    func startDate(for interactionId: LLMInteractionId) -> Date? {
        self.first { $0.interactionId == interactionId }?.date
    }
}
