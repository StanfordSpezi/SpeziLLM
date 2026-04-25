//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import GeneratedOpenAIClient


internal protocol LLMOpenAIChatClientProtocol {
    func createChatCompletion(_ input: Operations.createChatCompletion.Input) async throws -> Operations.createChatCompletion.Output

    func createResponse(_ input: Operations.createResponse.Input) async throws -> Operations.createResponse.Output

    func retrieveModel(_ input: Operations.retrieveModel.Input) async throws -> Operations.retrieveModel.Output
}

extension Client: LLMOpenAIChatClientProtocol {}
