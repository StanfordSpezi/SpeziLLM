//
// This source file is part of the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

/// The ``LLMError`` describes possible errors that occure during the execution of the ``LLM`` via the ``LLMRunner``.
public enum LLMError: Error {
    /// Indicates that the local model file is not found.
    case modelNotFound
    /// Indicates that the input text is too long.
    case inputTooLong
    /// Indicates that the generation breached the context limit.
    case contextLimit
    /// Indicates that the ``LLM`` is not yet ready, e.g., not initialized.
    case modelNotReadyYet
    /// Indicates that during generation an error occured.
    case generationError
}
