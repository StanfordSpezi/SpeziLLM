//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziLLM

extension LLMLocalSession {
    /// Updates the existing instance of the ``LLMLocalSchema`` with new parameters.
    ///
    /// - Parameters:
    ///   - model: An instance of `LLMLocalModel` to be used by the schema.
    ///   - parameters: A dictionary or object containing parameters that control the LLM generation process.
    ///   - samplingParameters: An object representing the sampling parameters for the LLM.
    ///   - injectIntoContext: A Boolean value indicating whether the inference output from the ``LLMLocalSession``
    ///     should be automatically inserted into the ``LLMLocalSession/context``. Defaults to `false`.
    ///
    /// - Important: Calling this method automatically invokes `cancel()`, stopping all running tasks associated
    ///   with the current session.
    public func update(
        parameters: LLMLocalParameters? = nil,
        samplingParameters: LLMLocalSamplingParameters? = nil,
        injectIntoContext: Bool? = nil // swiftlint:disable:this discouraged_optional_boolean
    ) {
        cancel()
        
        self.schema = .init(
            configuration: self.schema.configuration,
            parameters: parameters ?? self.schema.parameters,
            samplingParameters: samplingParameters ?? self.schema.samplingParameters,
            injectIntoContext: injectIntoContext ?? self.schema.injectIntoContext
        )
    }
}
