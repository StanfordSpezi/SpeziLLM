//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import MLXLLM
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
    
    /// Closure to properly format the ``LLMLocal/context`` to a `String` which is tokenized and passed to the LLM.
    let parameters: LLMLocalParameters
    /// Context parameters of the llama.cpp LLM.
    let contextParameters: LLMLocalContextParameters
    /// Sampling parameters of the llama.cpp LLM.
    let samplingParameters: LLMLocalSamplingParameters
    /// Closure to properly format the ``LLMLocal/context`` to a `String` which is tokenized and passed to the LLM.
    let formatChat: (@Sendable (LLMContext) throws -> String)
    /// Indicates if the inference output by the ``LLMLocalSession`` should automatically be inserted into the ``LLMLocalSession/context``.
    public let injectIntoContext: Bool
    /// The models configuration which is based on `mlx-libraries`
    internal let configuration: ModelConfiguration
    
    /// Creates an instance of the ``LLMLocalSchema`` containing all necessary configuration for local LLM inference.
    ///
    /// - Parameters:
    ///   - configuration: A local `URL` where the LLM file is stored. The format of the LLM must be in the llama.cpp `.gguf` format.
    ///   - generateParameters: Parameters controlling the LLM generation process.
    ///   - maxTokens: Maximum number of tokens to generate in a single output, defaults to 2048.
    ///   - displayEveryNTokens: Interval for displaying output after every N tokens generated, defaults to 4 (improve by ~15% compared to update at every token).
    ///   - injectIntoContext: Indicates if the inference output by the ``LLMLocalSession`` should automatically be inserted into the ``LLMLocalSession/context``, defaults to false.
    ///   - formatChat: Closure to properly format the ``LLMLocalSession/context`` to a `String` which is tokenized and passed to the LLM, defaults to Llama2 prompt format.
    public init(
        model: LLMLocalModel,
        parameters: LLMLocalParameters = .init(),
        contextParameters: LLMLocalContextParameters = .init(),
        samplingParameters: LLMLocalSamplingParameters = .init(),
        injectIntoContext: Bool = false,
        formatChat: @escaping (@Sendable (LLMContext) throws -> String)
    ) {
        self.parameters = parameters
        self.contextParameters = contextParameters
        self.samplingParameters = samplingParameters
        self.formatChat = formatChat
        self.injectIntoContext = injectIntoContext
        self.configuration = .init(id: model.hubID)
    }
}
