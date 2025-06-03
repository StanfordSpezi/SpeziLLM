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
/// - Important: The ``LLMFogSchema`` accepts a closure that returns an authorization token that is passed with every request to the Fog node in the `Bearer` HTTP field via the ``LLMFogParameters/init(modelType:overwritingAuthToken:systemPrompt:)``. The token is created via the closure upon every LLM inference request, as the ``LLMFogSession`` may be long lasting and the token could therefore expire. Ensure that the closure appropriately caches the token in order to prevent unnecessary token refresh roundtrips to external systems.
///
/// - Tip: For more information, refer to the documentation of the `LLMSchema` from SpeziLLM.
///
/// ### Usage
///
/// The code example below showcases a minimal instantiation of an ``LLMFogSchema``.
/// Note the `authToken` closure that is specified in the ``LLMFogSchema/init(parameters:modelParameters:injectIntoContext:)``, as this closure should return a token that is then passed as a `Bearer` HTTP token to the fog node with every LLM inference request.
///
/// ```swift
/// var schema = LLMFogSchema(
///     parameters: .init(
///         modelType: .llama7B,
///         overwritingAuthToken: .none,
///         systemPrompt: "You're a helpful assistant that answers questions from users.",
///     )
/// )
/// ```
public struct LLMFogSchema: LLMSchema, Sendable {
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
