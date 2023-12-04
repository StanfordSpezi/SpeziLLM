//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

/// The ``LLMHostingType`` indicates the hosting platform that a Spezi ``LLM`` should run on.
public enum LLMHostingType: String, CaseIterable {
    /// Local, on-device execution of the ``LLM``.
    case local
    /// Execution of the ``LLM`` in the fog layer.
    case fog
    /// Remote, cloud-based execution of the ``LLM``.
    case cloud
}
