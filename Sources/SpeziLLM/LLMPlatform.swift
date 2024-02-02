//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Spezi


public protocol LLMPlatform: Module, EnvironmentAccessible {
    associatedtype Schema: LLMSchema
    associatedtype Session: LLMSession
    
    @MainActor var state: LLMPlatformState { get }
    
    func callAsFunction(with: Schema) async -> Session
}


extension LLMPlatform {
    var schemaId: ObjectIdentifier {
        ObjectIdentifier(Schema.self)
    }
}
