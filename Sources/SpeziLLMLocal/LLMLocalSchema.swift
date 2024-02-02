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


public struct LLMLocalSchema: LLMSchema {
    public typealias Platform = LLMLocalPlatform
    
    /// The on-device `URL` where the model is located.
    let modelPath: URL
    /// Parameters of the llama.cpp ``LLM``.
    let parameters: LLMLocalParameters
    /// Context parameters of the llama.cpp ``LLM``.
    let contextParameters: LLMLocalContextParameters
    /// Sampling parameters of the llama.cpp ``LLM``.
    let samplingParameters: LLMLocalSamplingParameters
    /// Closure to properly format the ``LLMLocal/context`` to a `String` which is tokenized and passed to the `LLM`.
    let formatChat: ((Chat) throws -> String)
    public let injectIntoContext: Bool
    
    
    public init(
        modelPath: URL,
        parameters: LLMLocalParameters = .init(),
        contextParameters: LLMLocalContextParameters = .init(),
        samplingParameters: LLMLocalSamplingParameters = .init(),
        injectIntoContext: Bool = false,
        formatChat: @escaping ((Chat) throws -> String) = PromptFormattingDefaults.llama2
    ) {
        self.modelPath = modelPath
        self.parameters = parameters
        self.contextParameters = contextParameters
        self.samplingParameters = samplingParameters
        self.injectIntoContext = injectIntoContext
        self.formatChat = formatChat
    }
}
