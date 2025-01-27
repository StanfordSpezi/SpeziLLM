//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


/// Represents the state of local generation in an LLM process, where each case encapsulates the result of generation.
/// - `intermediate`: Indicates an intermediate generation output, with more output expected.
/// - `final`: Represents the final generation result, marking the completion of the process.
public enum LLMLocalGenerateState {
    case intermediate(String)
    case `final`(LLMLocalGenerationResult)
}
