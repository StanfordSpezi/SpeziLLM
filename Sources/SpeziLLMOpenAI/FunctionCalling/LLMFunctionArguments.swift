//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


/// The decoded arguments of a single ``LLMFunction`` invocation.
///
/// An ``LLMFunction`` instance is registered once in the schema and shared by every invocation the LLM requests, including
/// multiple invocations of the same function that are executed in parallel. The arguments therefore can't be stored on the
/// ``LLMFunction/Parameter``s themselves. Instead, the arguments of an invocation are decoded into an `LLMFunctionArguments`
/// value that is bound to the task executing ``LLMFunction/execute()`` via ``LLMFunctionArguments/current``, from where
/// the ``LLMFunction/Parameter``s read them.
package struct LLMFunctionArguments: Sendable {
    /// The arguments of the ``LLMFunction`` invocation that is executed by the current task (and its child tasks), if any.
    @TaskLocal static var current: LLMFunctionArguments?


    /// The decoded argument values, keyed by the identity of the ``LLMFunction/Parameter`` they belong to.
    /// Optional parameters the LLM omitted have no entry.
    private let values: [ObjectIdentifier: any Sendable]


    init(values: [ObjectIdentifier: any Sendable]) {
        self.values = values
    }


    /// Returns the decoded argument for the ``LLMFunction/Parameter`` identified by `parameter`, or `nil` if the LLM omitted it.
    func value(for parameter: ObjectIdentifier) -> (any Sendable)? {
        values[parameter]
    }
}


extension LLMFunction {
    /// Executes the ``LLMFunction`` with the passed arguments.
    ///
    /// The arguments are bound to the executing task for the duration of ``LLMFunction/execute()``, so that the
    /// ``LLMFunction/Parameter``s of this invocation, and only this invocation, observe them.
    ///
    /// - Parameter arguments: The arguments decoded via ``LLMFunction/decodeArguments(from:)``.
    /// - Returns: The output of ``LLMFunction/execute()``.
    package func execute(with arguments: LLMFunctionArguments) async throws -> String? {
        try await LLMFunctionArguments.$current.withValue(arguments) {
            try await execute()
        }
    }
}
