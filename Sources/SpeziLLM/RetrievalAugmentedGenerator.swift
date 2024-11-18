//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


/// A protocol defining a retrieval-augmented generation interface.
/// Classes or structs that conform to this protocol should implement
/// a retrieval method to fetch information based on a query string.
public protocol RetrievalAugmentedGenerator {

    /// Retrieves relevant information based on a query string.
    ///
    /// - Parameter query: A `String` representing the query for which information should be retrieved.
    /// - Returns: A `String` containing the retrieved information relevant to the provided query.
    ///
    /// Conforming types should implement this method to handle queries and
    /// return results that can be used for augmentation or content generation.
    func retrieve(query: String) async -> String?
}
