//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


/// Describes the current state of the ``LLMPlatform``.
/// The ``LLMPlatformState`` is quite minimal with only ``LLMPlatformState/idle`` and ``LLMPlatformState/processing`` states.
public enum LLMPlatformState {
    case idle
    case processing
}
