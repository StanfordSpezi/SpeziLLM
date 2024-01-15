//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import OpenAI

/// Represents an OpenAI Function that can be called by the LLM: https://platform.openai.com/docs/guides/function-calling
public protocol LLMFunction: Decodable {
    /// The name of the LLM function that is called, serves as the main identifier of the function.
    static var name: String { get }
    /// The description of the LLM function, enabling the LLM to understand the purpose of the function.
    static var description: String { get }
    
    
    /// Logic that is executed when the LLM calls a specific function.
    /// 
    /// - Returns: Textual output of the function call that is then provided to the LLM.
    func execute() async throws -> String
}
