//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import struct OpenAI.Chat
import struct OpenAI.ChatFunctionDeclaration
import struct OpenAI.ChatQuery
import class OpenAI.OpenAI
import struct OpenAI.Model
import struct OpenAI.ChatStreamResult
import struct OpenAI.APIErrorResponse
import os
import SpeziChat
import SpeziLLM


/// Generate output via the OpenAI GPT models.
/// 
/// ``LLMOpenAI`` is a Spezi `LLM` and provides access to text-based models from OpenAI, such as GPT-3.5 or GPT-4.
///
/// - Important: ``LLMOpenAI`` shouldn't be used on it's own but always wrapped by the Spezi `LLMRunner` as the runner handles
/// all management overhead tasks.
///
/// > Tip: ``SpeziLLMOpenAI`` also enables the function calling mechanism to establish a structured, bidirectional, and reliable communication between the OpenAI LLMs and external tools. For details, refer to ``LLMFunction`` and ``LLMFunction/Parameter`` or the <doc:Function-Calling> DocC article.
///
/// ### Usage
///
/// The code section below showcases a complete code example on how to use the ``LLMOpenAI`` in combination with a `LLMRunner` from the [SpeziLLM](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm) target.
///
/// - Important: The model can be queried via the `LLMGenerationTask/generate()` and `LLMGenerationTask/generate(prompt:)` calls (returned from wrapping the ``LLMOpenAI`` in the `LLMRunner` from the [SpeziLLM](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm) target).
/// The first method takes no input prompt at all but uses the current context of the model (so `LLM/context`) to query the model.
/// The second takes a `String`-based input from the user and appends it to the  context of the model (so `LLM/context`) before querying the model.
///
/// ```swift
/// class LLMOpenAIAppDelegate: SpeziAppDelegate {
///     override var configuration: Configuration {
///         Configuration {
///             LLMRunner {
///                 LLMOpenAIRunnerSetupTask()
///             }
///         }
///     }
/// }
///
/// struct LLMOpenAIChatView: View {
///    // The runner responsible for executing the OpenAI LLM.
///    @Environment(LLMRunner.self) var runner: LLMRunner
///
///    // The OpenAI LLM
///    @State var model: LLMOpenAI = .init(
///         parameters: .init(
///             modelType: .gpt3_5Turbo,
///             systemPrompt: "You're a helpful assistant that answers questions from users.",
///             overwritingToken: "abc123"
///         )
///    )
///    @State var responseText: String
///
///    func executePrompt(prompt: String) {
///         // Execute the query on the runner, returning a stream of outputs
///         let stream = try await runner(with: model).generate(prompt: "Hello LLM!")
///
///         for try await token in stream {
///             responseText.append(token)
///         }
///    }
/// }
/// ```
@Observable
public class LLMOpenAI: LLM {
    /// A Swift Logger that logs important information from the ``LLMOpenAI``.
    static let logger = Logger(subsystem: "edu.stanford.spezi", category: "SpeziLLM")
    
    @MainActor public var state: LLMState = .uninitialized
    @MainActor public var context: SpeziChat.Chat = []
    
    public let type: LLMHostingType = .cloud
    let parameters: LLMOpenAIParameters
    let modelParameters: LLMOpenAIModelParameters
    let functions: [String: LLMFunction]
    @ObservationIgnored private var wrappedModel: OpenAI?
    
    
    var model: OpenAI {
        guard let model = wrappedModel else {
            preconditionFailure("""
            SpeziLLMOpenAI: Illegal Access - Tried to access the wrapped OpenAI model of `LLMOpenAI` before being initialized.
            Ensure that the `LLMOpenAIRunnerSetupTask` is passed to the `LLMRunner` within the Spezi `Configuration`.
            """)
        }
        return model
    }
    
    
    /// Creates a ``LLMOpenAI`` instance that can then be passed to the `LLMRunner` for execution.
    ///
    /// - Parameters:
    ///    - parameters: LLM Parameters
    ///    - modelParameters: LLM Model Parameters
    ///    - functionsCollection: LLM Functions (tools) used for the OpenAI function calling mechanism.
    public init(
        parameters: LLMOpenAIParameters,
        modelParameters: LLMOpenAIModelParameters = .init(),
        @LLMFunctionBuilder _ functionsCollection: @escaping () -> _LLMFunctionCollection
    ) {
        self.parameters = parameters
        self.modelParameters = modelParameters
        self.functions = functionsCollection().functions
        
        Task { @MainActor in
            self.context.append(systemMessage: parameters.systemPrompt)
        }
    }
    
    
    public func setup(runnerConfig: LLMRunnerConfiguration) async throws {
        await MainActor.run {
            self.state = .loading
        }
        
        // Overwrite API token if passed
        if let overwritingToken = self.parameters.overwritingToken {
            self.wrappedModel = OpenAI(
                configuration: .init(
                    token: overwritingToken,
                    organizationIdentifier: LLMOpenAIRunnerSetupTask.openAIModel.configuration.organizationIdentifier,
                    host: LLMOpenAIRunnerSetupTask.openAIModel.configuration.host,
                    timeoutInterval: LLMOpenAIRunnerSetupTask.openAIModel.configuration.timeoutInterval
                )
            )
        } else {
            self.wrappedModel = LLMOpenAIRunnerSetupTask.openAIModel
        }
        
        do {
            _ = try await self.model.model(query: .init(model: self.parameters.modelType))
        } catch let error as URLError {
            throw LLMOpenAIError.connectivityIssues(error)
        } catch {
            LLMOpenAI.logger.error("""
            SpeziLLMOpenAI: Couldn't access the specified OpenAI model.
            Ensure the model exists and the configured API key is able to access the model.
            """)
            throw LLMOpenAIError.modelAccessError(error)
        }
        
        await MainActor.run {
            self.state = .ready
        }
    }
    
    public func generate(continuation: AsyncThrowingStream<String, Error>.Continuation) async {
        Self.logger.debug("SpeziLLMOpenAI: OpenAI GPT started a new inference")
        
        await MainActor.run {
            self.state = .generating
        }
        
        do {
            try await _generate(continuation: continuation)
            
            continuation.finish()
            
            await MainActor.run {
                self.state = .ready
            }
            
            Self.logger.debug("SpeziLLMOpenAI: OpenAI GPT completed an inference")
        } catch let error as APIErrorResponse {
            if error.error.code == LLMOpenAIError.insufficientQuota.openAIErrorMessage {
                LLMOpenAI.logger.error("""
                SpeziLLMOpenAI: Quota limit of OpenAI is reached. Ensure the configured API key has enough resources.
                """)
                await finishGenerationWithError(LLMOpenAIError.insufficientQuota, on: continuation)
            } else {
                LLMOpenAI.logger.error("""
                SpeziLLMOpenAI: OpenAI inference failed with a generation error.
                """)
                await finishGenerationWithError(LLMOpenAIError.generationError, on: continuation)
            }
        } catch let error as LLMOpenAIError {
            LLMOpenAI.logger.error("""
            SpeziLLMOpenAI: OpenAI inference failed with the OpenAIError: \(error.localizedDescription).
            """)
            await finishGenerationWithError(error, on: continuation)
        } catch {
            LLMOpenAI.logger.error("""
            SpeziLLMOpenAI: OpenAI inference failed with a generation error.
            """)
            await finishGenerationWithError(LLMOpenAIError.generationError, on: continuation)
        }
    }
}
