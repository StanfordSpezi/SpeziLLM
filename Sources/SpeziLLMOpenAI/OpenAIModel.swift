//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import struct OpenAI.Chat
import struct OpenAI.ChatFunctionDeclaration
import struct OpenAI.ChatQuery
import class OpenAI.OpenAI
@_exported import struct OpenAI.Model
@_exported import struct OpenAI.ChatStreamResult
import Foundation
import Observation
import SpeziChat
import SpeziSecureStorage


/// View model responsible for to coordinate the interactions with the OpenAI GPT API.
@Observable
public class OpenAIModel {
    private enum Defaults {
        static let defaultModel: Model = .gpt3_5Turbo
    }
    
    
    private let secureStorage: SecureStorage
    
    
    /// The OpenAI GPT Model type that is used to interact with the OpenAI API
    public var openAIModel: String {
        get {
            access(keyPath: \.openAIModel)
            return UserDefaults.standard.value(forKey: OpenAIConstants.modelStorageKey) as? Model ?? Defaults.defaultModel
        }
        set {
            withMutation(keyPath: \.openAIModel) {
                UserDefaults.standard.set(newValue, forKey: OpenAIConstants.modelStorageKey)
            }
        }
    }
    
    /// The API token used to interact with the OpenAI API
    public var apiToken: String? {
        get {
            access(keyPath: \.apiToken)
            return try? secureStorage.retrieveCredentials(OpenAIConstants.credentialsUsername, server: OpenAIConstants.credentialsServer)?.password
        }
        set {
            withMutation(keyPath: \.apiToken) {
                if let newValue {
                    try? secureStorage.store(
                        credentials: Credentials(username: OpenAIConstants.credentialsUsername, password: newValue),
                        server: OpenAIConstants.credentialsServer
                    )
                } else {
                    try? secureStorage.deleteCredentials(OpenAIConstants.credentialsUsername, server: OpenAIConstants.credentialsServer)
                }
            }
        }
    }
    
    
    init(secureStorage: SecureStorage, apiToken defaultToken: String? = nil, openAIModel model: Model? = nil) {
        self.secureStorage = secureStorage
        
        if UserDefaults.standard.object(forKey: OpenAIConstants.modelStorageKey) == nil {
            self.openAIModel = model ?? Defaults.defaultModel
        }
        
        if let apiTokenFromStorage = try? secureStorage.retrieveCredentials(
            OpenAIConstants.credentialsUsername,
            server: OpenAIConstants.credentialsServer
        )?.password {
            self.apiToken = apiTokenFromStorage
        } else {
            self.apiToken = defaultToken
        }
    }
    
    /// Queries the OpenAI API using the provided chat messages.
    /// Builds on top of the [SpeziChat](https://github.com/StanfordSpezi/SpeziChat) module to handle the `SpeziChat.Chat` data structure.
    ///
    /// - Parameters:
    ///   - chat: A collection of chat messages (from the `SpeziChat` dependency) used in the conversation.
    ///
    /// - Returns: The content of the response from the API.
    public func queryAPI(
        withChat chat: SpeziChat.Chat
    ) throws -> AsyncThrowingStream<ChatStreamResult, Error> {
        guard let apiToken, !apiToken.isEmpty else {
            throw OpenAIError.noAPIToken
        }
        
        let openAIChat: [Chat] = chat.map { speziChat in
            .init(
                role: Chat.Role(rawValue: speziChat.role.rawValue) ?? .assistant,
                content: speziChat.content
            )
        }
        
        return try self.queryAPI(withOpenAIChat: openAIChat)
    }
    
    /// Queries the OpenAI API using the provided chat messages.
    /// Supports advanced OpenAI functionality like Function Calling using the native OpenAI `[OpenAI.Chat]` data structure.
    ///
    /// - Parameters:
    ///   - chat: A collection of chat messages (from the `OpenAI` dependency) used in the conversation.
    ///   - chatFunctionDeclaration: OpenAI functions that should be injected in the OpenAI query.
    ///
    /// - Returns: The content of the response from the API.
    public func queryAPI(
        withOpenAIChat chat: [Chat],
        withFunction chatFunctionDeclaration: [ChatFunctionDeclaration] = []
    ) throws -> AsyncThrowingStream<ChatStreamResult, Error> {
        guard let apiToken, !apiToken.isEmpty else {
            throw OpenAIError.noAPIToken
        }
        
        let functions = chatFunctionDeclaration.isEmpty ? nil : chatFunctionDeclaration

        let openAIClient = OpenAI(apiToken: apiToken)
        let query = ChatQuery(model: openAIModel, messages: chat, functions: functions)
        return openAIClient.chatsStream(query: query)
    }
}
