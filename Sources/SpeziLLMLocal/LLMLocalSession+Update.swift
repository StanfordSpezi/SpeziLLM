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
    /// Creates a new ``LLMLocalSession`` with updated ``LLMLocalParameters`` and ``LLMLocalSamplingParameters``.
    ///
    /// - Parameters:
    ///   - parameters: A dictionary or object containing parameters that control the LLM generation process.
    ///   - samplingParameters: An object representing the sampling parameters for the LLM.
    ///   - injectIntoContext: A Boolean value indicating whether the inference output from the ``LLMLocalSession``
    ///     should be automatically inserted into the ``LLMLocalSession/context``. Defaults to `false`.
    ///
    /// - Important: Calling this method automatically invokes `cancel()`, stopping all running tasks associated
    ///   with the current session. The old session needs to be discarded then.
    public func update(
        parameters: LLMLocalParameters? = nil,
        samplingParameters: LLMLocalSamplingParameters? = nil,
        injectIntoContext: Bool? = nil // swiftlint:disable:this discouraged_optional_boolean
    ) -> LLMLocalSession {
        self.cancel()       // Cancels the old session

        return LLMLocalSession(
            self.platform,
            schema: LLMLocalSchema(
                configuration: self.schema.configuration,
                parameters: parameters ?? self.schema.parameters,
                samplingParameters: samplingParameters ?? self.schema.samplingParameters,
                injectIntoContext: injectIntoContext ?? self.schema.injectIntoContext
            )
        )
    }
}
