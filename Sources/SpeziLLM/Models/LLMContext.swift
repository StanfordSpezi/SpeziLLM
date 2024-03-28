//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


/// Represents the context of an ``LLMSession``.
///
/// A ``LLMContext`` is nothing more than an ordered array of ``LLMContextEntity``s which contain the content of the individual messages.
public typealias LLMContext = [LLMContextEntity]
