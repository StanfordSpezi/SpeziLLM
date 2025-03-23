//
//  Test.swift
//  SpeziLLM
//
//  Created by Sébastien Letzelter on 12.03.25.
//

import Testing
import SwiftUI
//import OpenAI
@testable import Spezi
@testable import SpeziLLM
@testable import SpeziLLMOpenAI
//@testable import SpeziSecureStorage
import GeneratedOpenAIClient
import OpenAPIRuntime




//class MockSecureStorage: Module, DefaultInitializable, EnvironmentAccessible, Sendable {
//    public required init() {}
//    public func createKey(_ tag: String, size: Int = 256, storageScope: SecureStorageScope = .secureEnclave) throws -> SecKey {
//        fatalError("not implemented")
//    }
//    public func retrievePrivateKey(forTag tag: String) throws -> SecKey? {
//        fatalError("not implemented")    }
//    public func retrievePublicKey(forTag tag: String) throws -> SecKey? {
//        fatalError("not implemented")
//    }
//    public func deleteKeys(forTag tag: String) throws {
//        fatalError("not implemented")
//    }
//    private func keyQuery(forTag tag: String) -> [String: Any] {
//        [:]
//    }
//    public func store(
//        credentials: Credentials,
//        server: String? = nil,
//        removeDuplicate: Bool = true,
//        storageScope: SecureStorageScope = .keychain
//    ) throws {
//
//    }
//}


// To enable tests that require an OpenAI API key:
// Open the `SpeziLLM-Package.xctestplan` file and navigate to
// Configurations > Environment Variables. Add a new variable:
//
//   Name:  OPENAI_API_TOKEN
//   Value: your-secret-key-here
class Test {
//    struct OpenAIProtocolMock: OpenAIProtocol {
//        static var firstTimeChatStream = true
//        func audioTranslations(query: AudioTranslationQuery, completion: @escaping (Result<AudioTranslationResult, any Error>) -> Void) {
//            fatalError("Not implemented")
//        }
//        
//        func audioTranscriptions(query: AudioTranscriptionQuery, completion: @escaping (Result<AudioTranscriptionResult, any Error>) -> Void) {
//            fatalError("Not implemented")
//        }
//        
//        func audioCreateSpeech(query: AudioSpeechQuery, completion: @escaping (Result<AudioSpeechResult, any Error>) -> Void) {
//            fatalError("Not implemented")
//        }
//        
//        func moderations(query: ModerationsQuery, completion: @escaping (Result<ModerationsResult, any Error>) -> Void) {
//            fatalError("Not implemented")
//        }
//        
//        func models(completion: @escaping (Result<ModelsResult, any Error>) -> Void) {
//            fatalError("Not implemented")
//        }
//        
//        func model(query: ModelQuery, completion: @escaping (Result<ModelResult, any Error>) -> Void) {
//            fatalError("Not implemented")
//        }
//        
//        func edits(query: EditsQuery, completion: @escaping (Result<EditsResult, any Error>) -> Void) {
//            fatalError("Not implemented")
//        }
//        
//        func chatsStream(query: ChatQuery, onResult: @escaping (Result<ChatStreamResult, any Error>) -> Void, completion: (((any Error)?) -> Void)?) {
//            let id = UUID().uuidString
//            let result: ChatStreamResult = ChatStreamResult(
//            
//            let chatStream: (String?) throws -> ChatStreamResult = { input in
//                try JSONDecoder().decode(ChatStreamResult.self, from: """
//                {
//                "id": "\(id)",
//                "object": "chat.completion.chunk",
//                "created": \(Date().timeIntervalSince1970),
//                "model": "spezi-mock",
//                "choices": [
//                    {
//                        "index": 0,
//                        "delta": {
//                            "content": \(input == nil ? "null" : "\"" + (input ?? "") + "\""),
//                            "role": \(input == nil ? "null" : "\"assistant\""),
//                        },
//                        "finishReason": \(input == nil ? "null" : "\"stop\"")
//                    }
//                ]
//                }
//                """.data(using: .utf8) ?? Data())
//            }
//            
//            let toolCall: () throws -> ChatStreamResult = {
//                try JSONDecoder().decode(ChatStreamResult.self, from: """
//                {
//                "id": "\(id)",
//                "object": "chat.completion.chunk",
//                "created": \(Date().timeIntervalSince1970),
//                "model": "spezi-mock",
//                "choices": [
//                    {
//                        "index": 0,
//                        "delta": {
//                            "content": null,
//                            "role": null,
//                            "tool_calls": [
//                                {
//                                    "index": 0,
//                                    "id": "call_F1lgJNgwramps3HpdZiRbZpt",
//                                    "function": {
//                                        "arguments": "{}",
//                                        "name": "perform_test"
//                                    },
//                                    "type": "function"
//                                }
//                            ]
//                        },
//                        "finishReason": null
//                    }
//                ]
//                }
//                """.data(using: .utf8) ?? Data())
//            }
//
//            do {
//                if(Test.OpenAIProtocolMock.firstTimeChatStream) {
//                    onResult(.success(try toolCall()))
//                    Test.OpenAIProtocolMock.firstTimeChatStream = false
//                    completion?(nil)
//                } else {
//                    onResult(.success(try chatStream("Hello ")))
//
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                        do {
//                            onResult(.success(try chatStream("world!")))
//                        } catch {
//                            print(error)
//                        }
//                    }
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                        do {
//                            onResult(.success(try chatStream(nil)))
//                        } catch {
//                            print(error)
//                        }
//                    }
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//                        completion?(nil)
//                    }
//                }
//            } catch {
//                print(error)
//                fatalError("JSON To ChatStreamResult conversion failed")
//            }
//        }
//        
//        func chats(query: ChatQuery, completion: @escaping (Result<ChatResult, any Error>) -> Void) {
//            fatalError("Not implemented")
//        }
//        
//        func embeddings(query: EmbeddingsQuery, completion: @escaping (Result<EmbeddingsResult, any Error>) -> Void) {
//            fatalError("Not implemented")
//        }
//        
//        func imageVariations(query: ImageVariationsQuery, completion: @escaping (Result<ImagesResult, any Error>) -> Void) {
//            fatalError("Not implemented")
//        }
//        
//        func imageEdits(query: ImageEditsQuery, completion: @escaping (Result<ImagesResult, any Error>) -> Void) {
//            fatalError("Not implemented")
//        }
//        
//        func images(query: ImagesQuery, completion: @escaping (Result<ImagesResult, any Error>) -> Void) {
//            fatalError("Not implemented")
//        }
//        
//        func completionsStream(query: CompletionsQuery, onResult: @escaping (Result<CompletionsResult, any Error>) -> Void, completion: (((any Error)?) -> Void)?) {
//            fatalError("Not implemented")
//        }
//        
//        public func completions(query: CompletionsQuery, completion: @escaping (Result<CompletionsResult, Error>) -> Void) {
////            performRequest(request: JSONRequest<CompletionsResult>(body: query, url: buildURL(path: .completions)), completion: completion)
//            fatalError("Not implemented")
//        }
//    }
    
    protocol ChatClientProtocol {
        func createChatCompletion(_ input: Operations.createChatCompletion.Input) async throws -> Operations.createChatCompletion.Output
    }
    
    final class MockChatClient: ChatClientProtocol {
        var createChatCompletionHandler: ((Operations.createChatCompletion.Input) async throws -> Operations.createChatCompletion.Output)?
        
        func createChatCompletion(_ input: Operations.createChatCompletion.Input) async throws -> Operations.createChatCompletion.Output {
            guard let handler = createChatCompletionHandler else {
                fatalError("Mock handler not set!")
            }
            return try await handler(input)
        }
    }

    struct LLMOpenAITestFunction: LLMFunction {
        static let name: String = "perform_test"
        static let description: String = "Performs a tests and returns a specific value to ensure this function has been called"
        
                
        func execute() async throws -> String? {
            "The value to return to ensure the test was succesful is \"abcdefghijklmnopqrstuvwxyz\""
        }
    }

    @MainActor
    @Test func testOpenAIInferenceTwo() async throws {
        guard let openAIToken = ProcessInfo.processInfo.environment["OPENAI_API_TOKEN"], !openAIToken.isEmpty else {
            print("Skipping OpenAI test – no API token provided.")
            return
        }
        
        let llmOpenAIPlatform = LLMOpenAIPlatform(configuration: LLMOpenAIPlatformConfiguration(apiToken: openAIToken))

        let runner = LLMRunner { llmOpenAIPlatform }
        try DependencyManager([runner]).resolve()
        runner.configure()
    
        
        let schema = LLMOpenAISchema(
            parameters: .init(modelType: .gpt4o_mini, overwritingToken: openAIToken)
        ) { }
        
        var context = LLMContext()
        context.append(userInput: "Hello!")
        

        // Build the expected output by wrapping the dummy response in the correct enum cases.
        let expectedOutput: Operations.createChatCompletion.Output = .ok(
            Operations.createChatCompletion.Output.Ok(
                body: 
                        .json(.init(id: "test", choices: Components.Schemas.CreateChatCompletionResponse.choicesPayload.init(), created: 0, model: "test", object: .chat_period_completion))
            )
        )
        
        let mockClient = MockChatClient()
        mockClient.createChatCompletionHandler = { input in
            // Optionally, verify the input is as expected
            return expectedOutput
        }

        
        let llmSession = llmOpenAIPlatform.callAsFunction(with: schema)
        llmSession.context = context
        llmSession.wrappedClient = mockClient
        var oneShot = ""
        print(llmSession.wrappedClient)
//
//        for try await stringPiece in try await llmSession.generate() {
//            oneShot.append(stringPiece)
//        }
//        


//        let oneShot: String = try await runner.oneShot(with: schema, context: context)
        print(oneShot)
        
        #expect(!oneShot.isEmpty)
    }
    
//    @MainActor
//    @Test func testOpenAIInference() async throws {
//        guard let openAIToken = ProcessInfo.processInfo.environment["OPENAI_API_TOKEN"], !openAIToken.isEmpty else {
//            print("Skipping OpenAI test – no API token provided.")
//            return
//        }
//
//        let llmOpenAIPlatform = LLMOpenAIPlatform(configuration: LLMOpenAIPlatformConfiguration(apiToken: openAIToken))
//                                             
//        let runner = LLMRunner { llmOpenAIPlatform }
//        try DependencyManager([runner]).resolve()
//        runner.configure()
//
//        let schema = LLMOpenAISchema(
//            parameters: .init(modelType: .gpt3_5Turbo, overwritingToken: openAIToken)
//        ) { }
//
//        var context = LLMContext()
//        context.append(userInput: "Hello!")
//        Task {
//            let oneShot: String = try await runner.oneShot(with: schema, context: context)
//            print(oneShot)
//
//            #expect(!oneShot.isEmpty)
//        }
//    }
    
//    @MainActor
//    @Test func testOpenAILocalMock() async throws {
//        let llmOpenAIPlatform = LLMOpenAIPlatform(configuration: LLMOpenAIPlatformConfiguration(apiToken: "openAPIToken"))
//                                             
//        let runner = LLMRunner { llmOpenAIPlatform }
//        try DependencyManager([runner]).resolve()
//        runner.configure()
//
//        var schema = LLMOpenAISchema(
//            parameters: .init(modelType: .gpt3_5Turbo, overwritingToken: "openAIToken")
//        ) {
//            LLMOpenAITestFunction()
//        }
//        schema.overwritingOpenAIProtocolFactory = {
//            OpenAIProtocolMock()
//        }
//
//        var context = LLMContext()
//        context.append(userInput: "Hello! Return me the value needed for this test")
//
//        let oneShot: String = try await runner.oneShot(with: schema, context: context)
//        print(oneShot)
//
//        #expect(!oneShot.isEmpty)
//    }

//    
//    @MainActor
//    @Test func testOpenAIFunctionCalling() async throws {
//        guard let openAIToken = ProcessInfo.processInfo.environment["OPENAI_API_TOKEN"], !openAIToken.isEmpty else {
//            print("Skipping OpenAI test – no API token provided.")
//            return
//        }
//
//        let llmOpenAIPlatform = LLMOpenAIPlatform(configuration: LLMOpenAIPlatformConfiguration(apiToken: openAIToken))
//                                             
//        let runner = LLMRunner { llmOpenAIPlatform }
//        try DependencyManager([runner]).resolve()
//        runner.configure()
//
//        let schema = LLMOpenAISchema(
//            parameters: .init(modelType: .gpt3_5Turbo, overwritingToken: openAIToken)
//        ) {
//            LLMOpenAITestFunction()
//        }
//        
//        var context = LLMContext()
//        context.append(userInput: "Hello! Return me the value needed for this test")
//
//        let oneShot: String = try await runner.oneShot(with: schema, context: context)
//        print(oneShot)
//
//        try #require(!oneShot.isEmpty)
//        #expect(oneShot.contains("abcdefghijklmnopqrstuvwxyz"))
//    }

}
