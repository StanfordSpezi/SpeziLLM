//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation

@resultBuilder
public enum ChainBuilder {
    public typealias Callable = (String) -> String
    
    public static func buildExpression(_ expression: @escaping Callable) -> [Callable] {
        [expression]
    }
    
    public static func buildBlock(_ children: [Callable]...) -> [Callable] {
        children.flatMap { $0 }
    }
    
    public static func buildOptional(_ component: [Callable]?) -> [Callable] {
        component ?? []
    }
    
    public static func buildEither(first: [Callable]) -> [Callable] {
        first
    }
    
    public static func buildEither(second: [Callable]) -> [Callable] {
        second
    }
    
    public static func buildArray(_ components: [Callable]) -> [Callable] {
        components.flatMap { $0 }
    }
    
    public static func buildLimitedAvailability(_ component: [Callable]) -> [Callable] {
        component
    }
    
    public static func buildFinalResult(_ component: [Callable]) -> ChainCollection {
        ChainCollection(functions: component)
    }
}
