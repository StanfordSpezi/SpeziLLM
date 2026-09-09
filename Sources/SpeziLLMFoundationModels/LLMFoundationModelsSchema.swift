//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziLLM


/// Defines the configuration of an ``LLMFoundationModelsSession``.
///
/// The schema captures the parameters used to drive Apple's on-device system language model
/// (provided by the `FoundationModels` framework). It is bound to ``LLMFoundationModelsPlatform``,
/// which turns it into an executable ``LLMFoundationModelsSession``.
///
/// - Tip: For an overview of the schema/session/platform pattern, see the documentation of `LLMSchema`.
public struct LLMFoundationModelsSchema: LLMSchema {
    public typealias Platform = LLMFoundationModelsPlatform

    /// Inference parameters.
    public let parameters: LLMFoundationModelsParameters
    /// Whether streamed output should be appended to ``LLMFoundationModelsSession/context``.
    public let injectIntoContext: Bool

    /// Creates a new schema.
    /// - Parameters:
    ///   - parameters: Inference parameters. Defaults to `.init()`.
    ///   - injectIntoContext: Whether streamed output should be appended to the context. Defaults to `false`.
    public init(
        parameters: LLMFoundationModelsParameters = .init(),
        injectIntoContext: Bool = false
    ) {
        self.parameters = parameters
        self.injectIntoContext = injectIntoContext
    }
}
