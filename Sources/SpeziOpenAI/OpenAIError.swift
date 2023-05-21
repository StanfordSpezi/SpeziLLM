//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


/// An error that can appear from an API call to the OpenAI API.
public enum OpenAIError: Error {
    /// There was no OpenAI API token provided.
    case noAPIToken
}
