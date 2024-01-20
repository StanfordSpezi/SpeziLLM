//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


// Only array items
public protocol LLMFunctionParameterArrayItem: Decodable {
    static var itemSchema: LLMFunctionParameterItemSchema { get }
}
