//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


/// Describes the current state of the ``LLMPlatform`` which is responsible for sending ``LLMSchema``s to execution via ``LLMSession``s.
/// 
/// The ``LLMPlatformState`` is quite minimal with only ``LLMPlatformState/idle`` and ``LLMPlatformState/processing`` states.
public enum LLMPlatformState {
    /// Indicates that the ``LLMPlatform`` is currently idle and doesn't execute any ``LLMSession``s.
    case idle
    /// Indicates that the ``LLMPlatform`` is currently processing and executing ``LLMSession``s.
    case processing
}
