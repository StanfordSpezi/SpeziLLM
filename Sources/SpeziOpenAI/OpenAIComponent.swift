//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


import OpenAI
import Spezi
import SpeziLocalStorage
import SpeziSecureStorage
import SwiftUI


/// `OpenAIComponent` is a module responsible for to coordinate the interactions with the OpenAI GPT API.
public class OpenAIComponent<ComponentStandard: Standard>: Component, ObservableObject, ObservableObjectProvider {
    @Dependency private var localStorage: LocalStorage
    @Dependency private var secureStorage: SecureStorage
    
    /// The OpenAI GPT Model type that is used to interact with the OpenAI API
    @AppStorage(OpenAIConstants.modelStorageKey) public var openAIModel: Model = .gpt3_5Turbo
    private var defaultAPIToken: String?
    
    /// The API token used to interact with the OpenAI API
    public var apiToken: String? {
        get {
            try? secureStorage.retrieveCredentials(OpenAIConstants.credentialsUsername, server: OpenAIConstants.credentialsServer)?.password
        }
        set {
            objectWillChange.send()
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
    
    
    /// Initializes a new instance of `OpenAIGPT` with the specified API token and OpenAI model.
    ///
    /// - Parameters:
    ///   - apiToken: The API token for the OpenAI API.
    ///   - openAIModel: The OpenAI model to use for querying.
    public init(apiToken: String? = nil, openAIModel model: Model? = nil) {
        if UserDefaults.standard.object(forKey: OpenAIConstants.modelStorageKey) == nil {
            self.openAIModel = openAIModel
        }
        
        defaultAPIToken = apiToken
    }
    
    
    public func configure() {
        if self.apiToken == nil, let defaultAPIToken {
            self.apiToken = defaultAPIToken
        }
    }
    

    /// Queries the OpenAI API using the provided messages.
    ///
    /// - Parameters:
    ///   - messages: A collection of chat  messages used in the conversation.
    ///
    /// - Returns: The content of the response from the API.
    public func queryAPI(withChat chat: [Chat]) async throws -> AsyncThrowingStream<ChatStreamResult, Error> {
        guard let apiToken, !apiToken.isEmpty else {
            throw OpenAIError.noAPIToken
        }

        let openAIClient = OpenAI(apiToken: apiToken)
        let query = ChatQuery(model: openAIModel, messages: chat)
        return openAIClient.chatsStream(query: query)
    }
}
