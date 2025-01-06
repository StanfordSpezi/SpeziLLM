//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation

public class PromptTemplate {
    let template: String
    
    public init(template: String) {
        self.template = template
    }
    
    public func callAsFunction(arguments: [String: String]) -> String {
        var result = template
        for (argument, value) in arguments {
            result = result.replacingOccurrences(of: argument, with: value)
        }
        return result
    }
}
