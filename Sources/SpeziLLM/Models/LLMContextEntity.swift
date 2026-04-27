//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
#if canImport(UIKit)
import class UIKit.UIImage
#elseif canImport(AppKit)
import AppKit
#endif


/// Identifies a single interaction between the user and the LLM.
///
/// E.g., if the user asks the LLM a question, and the LLM responds by triggering 2 tool calls and then with a response,
/// all 3 ``LLMContextEntity`` objects coming from the LLM would have the same ``LLMContextEntity/interactionId``,
/// allowing them to be logically grouped together.
public struct LLMInteractionId: Hashable, Sendable, Codable {
    /// The actual id of the interaction.
    ///
    /// Has no special meaning, and the format is not guaranteed to be stable.
    public let value: String

    /// Creates an interaction identifier from a raw string.
    public init(_ value: String) {
        self.value = value
    }

    /// Creates a fresh, random interaction identifier.
    public init() {
        self.value = UUID().uuidString
    }
}


/// Represents the basic building block of a Spezi ``LLMContext``.
///
/// A ``LLMContextEntity`` can be thought of as a single message entity within a ``LLMContext``
/// It consists of a ``LLMContextEntity/Role``, a unique identifier, a timestamp in the form of a `Date` as well as an `String`-based ``LLMContextEntity/content`` property which can contain Markdown-formatted text.
/// Furthermore, the ``LLMContextEntity/complete`` flag indicates if the current state of the ``LLMContextEntity`` is final and the content will not be updated anymore.
public struct LLMContextEntity: Codable, Equatable, Hashable, Identifiable, Sendable {
    /// Represents a tool call by the LLM, including its parameters
    public struct ToolCall: Codable, Equatable, Hashable, Sendable {
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
    public enum Role: Codable, Equatable, Hashable, Sendable {
        case system
        case user
        case assistant
        case toolCalls([ToolCall])
        /// Represents a thinking phase in a reasoning model.
        ///
        /// Might have a thinking summary associated (in the ``LLMContextEntity``'s content.
        /// Depending on the model, there might be multiple thinking phases associated with a single interaction,
        /// e.g. if the model decided to initiate a tool call.
        case assistantThinking
        case toolCallResponse(id: String, name: String)


        package var rawValue: String {
            switch self {
            case .user: "user"
            case .assistant: "assistant"
            case .toolCalls: "tool_calls"
            case .assistantThinking: "assistant_thinking"
            case .system: "system"
            case .toolCallResponse: "tool"
            }
        }
    }
    
    /// - Important: This type is not stable and will be removed in an upcoming release.
    package struct _ImageContent: Codable, Hashable, Sendable { // swiftlint:disable:this type_name
        package let contentType: String
        package let base64Image: String
    }
    
    /// Unique identifier of the ``LLMContextEntity``.
    public let id: UUID
    /// The creation date of the ``LLMContextEntity``.
    public let date: Date

    /// Identifier of the user → LLM interaction this entity belongs to.
    ///
    /// All entities produced by a single ``LLMSession/generate()`` call (including reasoning summaries,
    /// tool calls, tool outputs, and the final assistant response) share the same identifier. `nil` for
    /// entities not associated with a specific interaction (e.g. the system prompt or user input that hasn't
    /// yet triggered a generation).
    public let interactionId: LLMInteractionId?

    /// ``LLMContextEntity/Role`` associated with the ``LLMContextEntity``.
    public let role: Role
    /// Content of the ``LLMContextEntity``.
    public var content: String
    /// Indicates if the ``LLMContextEntity`` is complete and will not receive any additional content.
    public var complete: Bool

    /// The context entity's image payload, if applicable.
    ///
    /// If this property is non-nil, ``content`` will be ignored.
    ///
    /// - Important: This property is not stable and will be removed in an upcoming release.
    package let _imageContent: _ImageContent? // swiftlint:disable:this identifier_name


    /// Creates a ``LLMContextEntity`` which is the building block of a Spezi ``LLMContext``.
    ///
    /// - Parameters:
    ///    - role: ``LLMContextEntity/Role`` associated with the ``LLMContextEntity``.
    ///    - content: `String`-based content of the ``LLMContextEntity``. Can contain Markdown-formatted text.
    ///    - complete: Indicates if the content of the ``LLMContextEntity`` is complete and will not receive any additional content. Defaults to `true`.
    ///    - id: Unique identifier of the ``LLMContextEntity``, defaults to a randomly assigned id.
    ///    - date: Timestamp on when the ``LLMContextEntity`` was originally created, defaults to the current time.
    ///    - interactionId: Identifier of the user → LLM interaction this entity belongs to. Defaults to `nil`.
    public init(
        id: UUID = .init(),
        date: Date = .now,
        role: Role,
        interactionId: LLMInteractionId? = nil,
        content: some StringProtocol,
        complete: Bool
    ) {
        self.id = id
        self.date = date
        self.role = role
        self.interactionId = interactionId
        self.content = String(content)
        self.complete = complete
        self._imageContent = nil
    }
}


extension LLMContextEntity {
    #if canImport(UIKit)
    /// - Important: This type is not stable and will be removed in an upcoming release.
    public typealias _PlatformImage = UIImage // swiftlint:disable:this type_name
    #elseif canImport(AppKit)
    /// - Important: This type is not stable and will be removed in an upcoming release.
    public typealias _PlatformImage = NSImage // swiftlint:disable:this type_name
    #endif
    
    /// - Important: This type is not stable and will be removed in an upcoming release.
    public enum _ImageFormat: Sendable { // swiftlint:disable:this type_name
        case png
        case jpeg(compressionFactor: Double)
        
        fileprivate var contentType: String {
            switch self {
            case .png:
                "image/png"
            case .jpeg:
                "image/jpeg"
            }
        }
    }
    
    /// - Important: This init is not stable and will be removed in an upcoming release.
    public init?(
        _role: Role, // swiftlint:disable:this identifier_name
        image: _PlatformImage,
        format: _ImageFormat,
        complete: Bool,
        id: UUID = UUID(),
        date: Date,
        interactionId: LLMInteractionId? = nil
    ) {
        let imageData: Data? = switch format {
        case .png:
            image.pngData()
        case .jpeg(let compressionFactor):
            image.jpegData(compressionQuality: compressionFactor)
        }
        guard let imageBase64 = imageData?.base64EncodedString() else {
            return nil
        }
        self.role = _role
        self.content = ""
        self._imageContent = .init(contentType: format.contentType, base64Image: imageBase64)
        self.complete = complete
        self.id = id
        self.date = date
        self.interactionId = interactionId
    }
}


#if canImport(AppKit)
extension NSImage {
    fileprivate func pngData() -> Data? {
        tiffRepresentation
            .flatMap { NSBitmapImageRep(data: $0) }?
            .representation(using: .png, properties: [:])
    }
    
    fileprivate func jpegData(compressionQuality: Double) -> Data? {
        tiffRepresentation
            .flatMap { NSBitmapImageRep(data: $0) }?
            .representation(using: .jpeg, properties: [.compressionFactor: compressionQuality])
    }
}
#endif
