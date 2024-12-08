//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// Represents the basic building block of a Spezi ``LLMContext``.
///
/// A ``LLMContextEntity`` can be thought of as a single message entity within a ``LLMContext``
/// It consists of a ``LLMContextEntity/Role``, a unique identifier, a timestamp in the form of a `Date` as well as an `String`-based ``LLMContextEntity/content`` property which can contain Markdown-formatted text.
/// Furthermore, the ``LLMContextEntity/complete`` flag indicates if the current state of the ``LLMContextEntity`` is final and the content will not be updated anymore.
public struct LLMContextEntity: Codable, Equatable, Hashable, Identifiable {
    /// Represents a tool call by the LLM, including its parameters
    public struct ToolCall: Codable, Equatable, Hashable {
        /// The ID of the function call, uniquely identifying the specific function call and matching the response to it.
        public let id: String
        /// The name of the function call.
        public let name: String
        /// The arguments as JSON of the function call.
        public let arguments: String
        
        
        /// Create a new ``LLMContextEntity/ToolCall``.
        ///
        /// - Parameters:
        ///    - id: The ID of the function call.
        ///    - name: The name of the function call.
        ///    - arguments: The arguments of the function call.
        public init(id: String, name: String, arguments: String) {
            self.id = id
            self.name = name
            self.arguments = arguments
        }
    }
    
    /// Indicates which ``LLMContextEntity/Role`` is associated with a ``LLMContextEntity``.
    public enum Role: Codable, Equatable, Hashable {
        case user
        case assistant(toolCalls: [ToolCall] = [])
        case system
        case tool(id: String, name: String)
        
        
        public var rawValue: String {
            switch self {
            case .user: "user"
            case .assistant: "assistant"
            case .system: "system"
            case .tool: "tool"
            }
        }
    }
    
    /// ``LLMContextEntity/Role`` associated with the ``LLMContextEntity``.
    public let role: Role
    /// `String`-based content of the ``LLMContextEntity``.
    public let content: String
    /// Indicates if the ``LLMContextEntity`` is complete and will not receive any additional content.
    public let complete: Bool
    /// Unique identifier of the ``LLMContextEntity``.
    public let id: UUID
    /// The creation date of the ``LLMContextEntity``.
    public let date: Date
    
    
    /// Creates a ``LLMContextEntity`` which is the building block of a Spezi ``LLMContext``.
    ///
    /// - Parameters:
    ///    - role: ``LLMContextEntity/Role`` associated with the ``LLMContextEntity``.
    ///    - content: `String`-based content of the ``LLMContextEntity``. Can contain Markdown-formatted text.
    ///    - complete: Indicates if the content of the ``LLMContextEntity`` is complete and will not receive any additional content. Defaults to `true`.
    ///    - id: Unique identifier of the ``LLMContextEntity``, defaults to a randomly assigned id.
    ///    - date: Timestamp on when the ``LLMContextEntity`` was originally created, defaults to the current time.
    public init<Content: StringProtocol>(
        role: Role,
        content: Content,
        complete: Bool = true,
        id: UUID = .init(),
        date: Date = .now
    ) {
        self.role = role
        self.content = String(content)
        self.complete = complete
        self.id = id
        self.date = date
    }
}
