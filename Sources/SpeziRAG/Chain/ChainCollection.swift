//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

public class ChainCollection {
    typealias Callable = (String) -> String
    
    let functions: [Callable]
    
    init(functions: [Callable]) {
        self.functions = functions
    }
}
