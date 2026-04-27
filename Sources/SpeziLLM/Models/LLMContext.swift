//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// Represents the context of an ``LLMSession``.
///
/// An `LLMContext` is an ordered collection of the messages and other items that make up the conversation with the LLM.
/// It also provides operations for working with this context, for example to add or update entities.
///
/// `LLMContext` should be thought of as an "append-only" type, in that most of its operations will either add an entirely new entity to the context, or will append content to the last (i.e., most recent) entity.
///
/// ## Topics
///
/// ### Initializers
/// - ``init()``
/// - ``init(_:)``
/// - ``init(systemMessages:)``
/// - ``init(arrayLiteral:)``
///
/// ### Operations
/// - ``append(systemMessage:to:)``
/// - ``append(userMessage:id:date:interactionId:)``
/// - ``append(assistantOutputDelta:isComplete:interactionId:)``
/// - ``markAssistantOutputCompleted()``
public struct LLMContext: Hashable, Sendable {
    @usableFromInline var storage: [LLMContextEntity]
    
    /// Creates a new, empty context.
    public init() {
        storage = []
    }
    
    /// Creates a context from a seqence of context entities.
    public init(_ elements: some Sequence<LLMContextEntity>) {
        storage = Array(elements)
    }
}


extension LLMContext: ExpressibleByArrayLiteral {
    /// Creates a context from an array literal.
    public init(arrayLiteral elements: LLMContextEntity...) {
        self.init(elements)
    }
}


extension LLMContext: RandomAccessCollection, RangeReplaceableCollection, MutableCollection {
    public var startIndex: Int {
        storage.startIndex
    }
    
    public var endIndex: Int {
        storage.endIndex
    }
    
    public mutating func replaceSubrange(_ subrange: Range<Int>, with newElements: some Collection<LLMContextEntity>) {
        storage.replaceSubrange(subrange, with: newElements)
    }
    
    public subscript(position: Int) -> LLMContextEntity {
        get {
            storage[position]
        }
        set {
            storage[position] = newValue
        }
    }
}


// MARK: LLMContext Operations

extension LLMContext {
    /// Creates a context from a sequence of system messages.
    public init(systemMessages: some Sequence<String>) {
        self.init(systemMessages.map { msg in
            LLMContextEntity(
                date: .now,
                role: .system,
                content: msg,
                complete: true
            )
        })
    }
    
    /// Clears the context.
    ///
    /// - parameter keepLeadingSystemMessages: Whether system messages that appear at the beginning of the context should be kept.
    ///     System messages that are preceded by a non-system-message entity will always be removed.
    public mutating func clear(keepLeadingSystemMessages: Bool) {
        if keepLeadingSystemMessages {
            storage = Array(storage.prefix { $0.role == .system })
        } else {
            storage.removeAll()
        }
    }
}


extension LLMContext {
    /// Controls System Prompt Insertion
    public enum SystemMessageInsertDestination {
        /// The new system message should be appended to the leading system messages within the context, i.e., inserted after the last leading system message.
        case leadingSystemMessages
        /// The system message should be appended at the end of the whole context
        case wholeContext
    }
    
    
    /// Appends a system prompt to the context.
    ///
    /// - parameter systemMessage: The actual prompt that should be added
    /// - parameter position: Where the prompt should be placed within the context.
    public mutating func append(systemMessage: some StringProtocol, to position: SystemMessageInsertDestination) {
        let entity = LLMContextEntity(
            date: .now,
            role: .system,
            content: systemMessage,
            complete: true
        )
        switch position {
        case .leadingSystemMessages:
            if let index = storage.lastIndex(where: { $0.role == .system }) {
                // Insert new system prompt after the existing ones
                storage.insert(entity, at: index + 1)
            } else {
                // If no system prompt exists yet, insert at the very beginning
                storage.insert(entity, at: 0)
            }
        case .wholeContext:
            storage.append(entity)
        }
    }
}


extension LLMContext {
    /// Appends a new user message entity to the end of the context.
    public mutating func append(
        userMessage: some StringProtocol,
        id: UUID = .init(),
        date: Date = .now,
        interactionId: LLMInteractionId? = nil
    ) {
        storage.append(.init(
            id: id,
            date: date,
            role: .user,
            interactionId: interactionId,
            content: userMessage,
            complete: true
        ))
    }
}


extension LLMContext {
    /// Appends an assistant output delta to the context, creating a new entity if necessary.
    public mutating func append(
        assistantOutputDelta delta: some StringProtocol,
        isComplete: Bool,
        interactionId: LLMInteractionId? = nil
    ) {
        if let last, last.role == .assistant, last.interactionId == interactionId, !last.complete {
            self[endIndex - 1].content.append(contentsOf: delta)
            if isComplete {
                self[endIndex - 1].complete = true
            }
        } else {
            // if there is no last message that matches the message we wish to append to, we create a new one.
            storage.append(.init(
                date: .now,
                role: .assistant,
                interactionId: interactionId,
                content: delta,
                complete: isComplete
            ))
        }
    }
    
    /// Marks the latest chat entity as completed, if it is an assistant message.
    public mutating func markAssistantOutputCompleted() {
        if let last, last.role == .assistant {
            self[endIndex - 1].complete = true
        }
    }
    
    
    @available(*, deprecated, renamed: "markAssistantOutputCompleted")
    public mutating func completeAssistantStreaming() { // swiftlint:disable:this missing_docs
        markAssistantOutputCompleted()
    }
    
    
    /// Appends a `toolCalls` entity to the context.
    public mutating func append(
        toolCalls: [LLMContextEntity.ToolCall],
        interactionId: LLMInteractionId?
    ) {
        storage.append(.init(
            date: .now,
            role: .toolCalls(toolCalls),
            interactionId: interactionId,
            content: "",
            complete: true
        ))
    }
    
    /// Appends a tool call response entity to the context.
    public mutating func append(
        toolCallResponse response: String,
        for functionName: String,
        withId functionId: String,
        interactionId: LLMInteractionId?
    ) {
        storage.append(.init(
            date: .now,
            role: .toolCallResponse(id: functionId, name: functionName),
            interactionId: interactionId,
            content: response,
            complete: true
        ))
    }
}


// MARK: Thinking

extension LLMContext {
    /// Ensures there is an in-progress ``LLMContextEntity/Role-swift.enum/assistantThinking`` entity at the end of the context.
    ///
    /// - parameter interactionId: The interaction this thinking phase belongs to. Used when creating a new entity.
    package mutating func beginAssistantThinkingPlaceholder(with interactionId: LLMInteractionId?) {
        if let last = self.last, case .assistantThinking = last.role, !last.complete {
            return
        }
        storage.append(.init(
            role: .assistantThinking,
            interactionId: interactionId,
            content: "",
            complete: false
        ))
    }
    
    /// Marks the latest chat entry as ``LLMContextEntity/complete``, if its role is ``LLMContextEntity/Role-swift.enum/assistantThinking``.
    package mutating func completeAssistantThinkingStreaming(for interactionId: LLMInteractionId) {
        for idx in self.indices.reversed() {
            if self[idx].interactionId == interactionId, self[idx].role == .assistantThinking {
                self[idx].complete = true
            }
        }
    }
    
    /// Appends a thinking delta to the latest ``LLMContextEntity/Role-swift.enum/assistantThinking`` entry, or starts a new one.
    ///
    /// Use ``beginAssistantThinkingPlaceholder(interactionId:)`` to mark the boundary between reasoning summary parts;
    /// this method then appends incoming deltas onto the active thinking entity.
    package mutating func append(
        assistantThinkingDelta delta: some StringProtocol,
        isComplete: Bool = false,
        interactionId: LLMInteractionId? = nil
    ) {
        // Continue the active thinking entity only if it's still in-progress. A finalized thinking
        // entity (complete == true) is treated as closed: a new delta starts a new entity instead of
        // (a) appending to a finalized record or (b) demoting it back to incomplete.
        if let last, case .assistantThinking = last.role, !last.complete, last.interactionId == interactionId {
            self[endIndex - 1].content.append(contentsOf: delta)
            if isComplete {
                self[endIndex - 1].complete = true
            }
        } else {
            storage.append(.init(
                role: .assistantThinking,
                interactionId: interactionId,
                content: delta,
                complete: isComplete
            ))
        }
    }

    /// Removes the trailing ``LLMContextEntity/Role-swift.enum/assistantThinking`` entity, if it is still in-progress.
    package mutating func removeIncompleteAssistantThinking(for interactionId: LLMInteractionId) {
        if let last, last.role == .assistantThinking, last.interactionId == interactionId {
            storage.removeLast()
        }
    }
    
    /// Determines the start date of the specified interaction's initial thinking phase.
    func startDate(for interactionId: LLMInteractionId) -> Date? {
        self.first { $0.interactionId == interactionId }?.date
    }
}
