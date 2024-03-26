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


/// Defines the type and configuration of the ``LLMFogSession``.
///
/// The ``LLMFogSchema`` is used as a configuration for the to-be-used Fog LLM. It contains all information necessary for the creation of an executable ``LLMFogSession``.
/// It is bound to the ``LLMFogPlatform`` that is responsible for turning the ``LLMFogSchema`` to an ``LLMFogSession``.
///
/// - Tip: For more information, refer to the documentation of the `LLMSchema` from SpeziLLM.
public struct LLMFogSchema: LLMSchema, @unchecked Sendable {
    public typealias Platform = LLMFogPlatform
    
    
    let parameters: LLMFogParameters
    let modelParameters: LLMFogModelParameters
    public let injectIntoContext: Bool
    
    
    /// Creates an instance of the ``LLMFogSchema`` containing all necessary configuration for Fog LLM inference.
    ///
    /// - Parameters:
    ///    - parameters: Parameters of the Fog LLM client.
    ///    - modelParameters: Parameters of the used Fog LLM.
    ///    - injectIntoContext: Indicates if the inference output by the ``LLMFogSession`` should automatically be inserted into the ``LLMFogSession/context``, defaults to false.
    public init(
        parameters: LLMFogParameters,
        modelParameters: LLMFogModelParameters = .init(),
        injectIntoContext: Bool = false
    ) {
        self.parameters = parameters
        self.modelParameters = modelParameters
        self.injectIntoContext = injectIntoContext
    }
}
