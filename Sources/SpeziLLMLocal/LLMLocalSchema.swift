//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import MLXLLM
import MLXLMCommon
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
    /// Sampling parameters of the LLM.
    let samplingParameters: LLMLocalSamplingParameters
    /// Indicates if the inference output by the ``LLMLocalSession`` should automatically be inserted into the ``LLMLocalSession/context``.
    public let injectIntoContext: Bool
    /// The models configuration which is based on `mlx-libraries`
    internal let configuration: ModelConfiguration
    
    /// Creates an instance of the ``LLMLocalSchema`` containing all necessary configuration for local LLM inference.
    ///
    /// - Parameters:
    ///   - model: The `LLMLocalModel` to be used by the schema.
    ///   - parameters: Parameters controlling the LLM generation process.
    ///   - samplingParameters: Represents the sampling parameters of the LLM.
    ///   - injectIntoContext: Indicates if the inference output by the ``LLMLocalSession`` should automatically be inserted into the ``LLMLocalSession/context``, defaults to false.
    public init(
        model: LLMLocalModel,
        parameters: LLMLocalParameters = .init(),
        samplingParameters: LLMLocalSamplingParameters = .init(),
        injectIntoContext: Bool = false
    ) {
        self.parameters = parameters
        self.samplingParameters = samplingParameters
        self.injectIntoContext = injectIntoContext
        self.configuration = .init(id: model.hubID)
    }
    
    @_disfavoredOverload
    internal init(
        configuration: ModelConfiguration,
        parameters: LLMLocalParameters = .init(),
        samplingParameters: LLMLocalSamplingParameters = .init(),
        injectIntoContext: Bool = false
    ) {
        self.configuration = configuration
        self.parameters = parameters
        self.samplingParameters = samplingParameters
        self.injectIntoContext = injectIntoContext
    }
}
