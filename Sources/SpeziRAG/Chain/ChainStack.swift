//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SwiftUI


// https://medium.com/@jhoomuck/composing-asynchronous-functions-in-swift-acd24cf5b94a

public struct ChainStack {
    private let collection: ChainCollection
    
    public init(
        @ChainBuilder _ content: @escaping () -> ChainCollection
    ) {
        let collection = content()
        self.collection = collection

    }
}

