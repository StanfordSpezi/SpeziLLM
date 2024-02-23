//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziChat
import SpeziLLM


/// Defines the type and configuration of the ``LLMLocalSession``.
///
/// The ``LLMLocalSchema`` is used as a configuration for the to-be-used local LLM. It contains all information necessary for the creation of an executable ``LLMLocalSession``.
/// It is bound to a ``LLMLocalPlatform`` that is responsible for turning the ``LLMLocalSchema`` to an ``LLMLocalSession``.
///
/// - Tip: For more information, refer to the documentation of the `LLMSchema` from SpeziLLM.
public struct LLMLocalSchema: LLMSchema {
    public typealias Platform = LLMLocalPlatform
    
    
    /// The on-device `URL` where the model is located.
    let modelPath: URL
    /// Parameters of the llama.cpp LLM.
    let parameters: LLMLocalParameters
    /// Context parameters of the llama.cpp LLM.
    let contextParameters: LLMLocalContextParameters
    /// Sampling parameters of the llama.cpp LLM.
    let samplingParameters: LLMLocalSamplingParameters
    /// Closure to properly format the ``LLMLocal/context`` to a `String` which is tokenized and passed to the LLM.
    let formatChat: (@Sendable (Chat) throws -> String)
    public let injectIntoContext: Bool
    
    
    /// Creates an instance of the ``LLMLocalSchema`` containing all necessary configuration for local LLM inference.
    ///
    /// - Parameters:
    ///   - modelPath: A local `URL` where the LLM file is stored. The format of the LLM must be in the llama.cpp `.gguf` format.
    ///   - parameters: Parameterize the LLM via ``LLMLocalParameters``.
    ///   - contextParameters: Configure the context of the LLM via ``LLMLocalContextParameters``.
    ///   - samplingParameters: Parameterize the sampling methods of the LLM via ``LLMLocalSamplingParameters``.
    ///   - injectIntoContext: Indicates if the inference output by the ``LLMLocalSession`` should automatically be inserted into the ``LLMLocalSession/context``, defaults to false.
    ///   - formatChat: Closure to properly format the ``LLMLocalSession/context`` to a `String` which is tokenized and passed to the LLM, defaults to Llama2 prompt format.
    public init(
        modelPath: URL,
        parameters: LLMLocalParameters = .init(),
        contextParameters: LLMLocalContextParameters = .init(),
        samplingParameters: LLMLocalSamplingParameters = .init(),
        injectIntoContext: Bool = false,
        formatChat: @escaping (@Sendable (Chat) throws -> String) = PromptFormattingDefaults.llama2
    ) {
        self.modelPath = modelPath
        self.parameters = parameters
        self.contextParameters = contextParameters
        self.samplingParameters = samplingParameters
        self.injectIntoContext = injectIntoContext
        self.formatChat = formatChat
    }
}
