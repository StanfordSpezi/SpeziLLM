//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


import OpenAI
import Spezi
import SpeziSecureStorage


/// `OpenAIModule` is a module responsible for to coordinate the interactions with the OpenAI GPT API.
public class OpenAIModule: Module, DefaultInitializable {
    /// Model accessible to modules using the ``OpenAIModule`` as a dependency and injected in the SwiftUI environment.
    @Module.Model public var model: OpenAIModel
    @Dependency private var secureStorage: SecureStorage
    
    
    private var defaultAPIToken: String?
    private var defaultOpenAIModel: Model?
    
    
    /// Initializes a new instance of `OpenAIModule` with the specified API token and OpenAI model.
    ///
    /// - Parameters:
    ///   - apiToken: The API token for the OpenAI API.
    ///   - openAIModel: The OpenAI model to use for querying.
    public init(apiToken: String? = nil, openAIModel: Model? = nil) {
        defaultAPIToken = apiToken
        defaultOpenAIModel = openAIModel
    }
    
    public required convenience init() {
        self.init(apiToken: nil, openAIModel: nil)
    }
    
    
    public func configure() {
        self.model = OpenAIModel(secureStorage: secureStorage, apiToken: defaultAPIToken, openAIModel: defaultOpenAIModel)
    }
}
