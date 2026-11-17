//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

@testable import SpeziLLM
@testable import SpeziLLMOpenAI
import Testing


/// Verifies that every invocation of an ``LLMFunction`` observes exactly the arguments sent by the LLM for that invocation,
/// even though all invocations share the single ``LLMFunction`` instance registered in the schema.
@Suite("LLM OpenAI Function Call Argument Isolation Tests")
class LLMOpenAIFunctionArgumentIsolationTests: LLMOpenAIInferenceTests {
    typealias MockChatClient = LLMOpenAIMockedInferenceTests.MockChatClient
    typealias ChatResponseBuilder = LLMOpenAIMockedInferenceTests.ChatResponseBuilder


    /// Suspends every caller until `expectedArrivals` callers have arrived, forcing function invocations to overlap.
    actor Barrier {
        private let expectedArrivals: Int
        private var arrivals = 0
        private var waiters: [CheckedContinuation<Void, Never>] = []


        init(expectedArrivals: Int) {
            self.expectedArrivals = expectedArrivals
        }


        func arriveAndWait() async {
            arrivals += 1
            guard arrivals < expectedArrivals else {
                waiters.forEach { $0.resume() }
                waiters.removeAll()
                return
            }

            await withCheckedContinuation { continuation in
                waiters.append(continuation)
            }
        }
    }

    struct EchoFunction: LLMFunction {
        static let name: String = "echo_arguments"
        static let description: String = "Echoes the arguments it was called with."

        let barrier: Barrier?

        @Parameter(description: "The value to echo")
        var value: String
        @Parameter(description: "An optional note to echo")
        var note: String?


        init(barrier: Barrier? = nil) {
            self.barrier = barrier
        }


        static func response(value: String, note: String?, valueAfterSuspension: String? = nil) -> String {
            "value=\(value);valueAfterSuspension=\(valueAfterSuspension ?? value);note=\(note ?? "nil")"
        }


        func execute() async throws -> String? {
            let valueBeforeSuspension = value
            // Wait until all concurrent invocations have started (and received their arguments) before reading again.
            await barrier?.arriveAndWait()
            await Task.yield()
            let valueAfterSuspension = value

            return Self.response(value: valueBeforeSuspension, note: note, valueAfterSuspension: valueAfterSuspension)
        }
    }


    @MainActor
    @Test("Concurrent invocations of the same function each observe their own arguments", .timeLimit(.minutes(1)))
    func testConcurrentInvocationsObserveOwnArguments() async throws {
        let schema = LLMOpenAISchema(parameters: .init(modelType: .gpt4o_mini)) {
            EchoFunction(barrier: Barrier(expectedArrivals: 2))
        }
        let llmSession = try initTestLLMSession(schema)
        let functions = schema.functions

        async let firstCall = llmSession.callFunction(
            availableFunctions: functions,
            functionCallArgs: .init(name: EchoFunction.name, id: "call-1", arguments: #"{"value": "first"}"#),
            failureHandling: .throwError
        )
        async let secondCall = llmSession.callFunction(
            availableFunctions: functions,
            functionCallArgs: .init(name: EchoFunction.name, id: "call-2", arguments: #"{"value": "second", "note": "a note"}"#),
            failureHandling: .throwError
        )
        let (firstResponse, secondResponse) = try await (firstCall, secondCall)

        #expect(firstResponse.functionID == "call-1")
        #expect(firstResponse.response == EchoFunction.response(value: "first", note: nil))
        #expect(secondResponse.functionID == "call-2")
        #expect(secondResponse.response == EchoFunction.response(value: "second", note: "a note"))
    }

    @MainActor
    @Test("An omitted optional argument is nil and does not keep the previous invocation's value")
    func testOmittedOptionalArgumentIsNil() async throws {
        let schema = LLMOpenAISchema(parameters: .init(modelType: .gpt4o_mini)) {
            EchoFunction()
        }
        let llmSession = try initTestLLMSession(schema)

        let firstResponse = try await llmSession.callFunction(
            availableFunctions: schema.functions,
            functionCallArgs: .init(name: EchoFunction.name, id: "call-1", arguments: #"{"value": "first", "note": "a note"}"#),
            failureHandling: .throwError
        )
        #expect(firstResponse.response == EchoFunction.response(value: "first", note: "a note"))

        let secondResponse = try await llmSession.callFunction(
            availableFunctions: schema.functions,
            functionCallArgs: .init(name: EchoFunction.name, id: "call-2", arguments: #"{"value": "second"}"#),
            failureHandling: .throwError
        )
        #expect(secondResponse.response == EchoFunction.response(value: "second", note: nil))
    }

    @MainActor
    @Test("Parallel tool calls in one model response each observe their own arguments", .timeLimit(.minutes(1)))
    func testParallelToolCallsDuringGeneration() async throws {
        var context = LLMContext()
        context.append(userInput: "Echo two values.")

        let schema = LLMOpenAISchema(parameters: .init(modelType: .gpt4o_mini)) {
            EchoFunction(barrier: Barrier(expectedArrivals: 2))
        }
        let llmSession = try initTestLLMSession(schema)
        llmSession.context = context
        let mockClient = MockChatClient()
        llmSession.wrappedClient = mockClient

        var chatCompletionCalls = 0
        mockClient.createChatCompletionHandler = { input in
            var builder = ChatResponseBuilder()

            if chatCompletionCalls == 0 {
                try builder.append(functionName: EchoFunction.name, arguments: #"{"value": "first", "note": "a note"}"#, toolCallIndex: 0)
                try builder.append(functionName: EchoFunction.name, arguments: #"{"value": "second"}"#, toolCallIndex: 1)
            } else {
                if case let .json(inputBody) = input.body {
                    let messages = inputBody.messages.description
                    #expect(messages.contains(EchoFunction.response(value: "first", note: "a note")))
                    #expect(messages.contains(EchoFunction.response(value: "second", note: nil)))
                } else {
                    Issue.record("Failed to parse JSON input body")
                }

                try builder.append(text: "Done")
            }
            builder.done()

            chatCompletionCalls += 1
            return builder.toChatOutput()
        }

        var oneShot = ""
        for try await stringPiece in try await llmSession.generate() {
            oneShot.append(stringPiece)
        }

        #expect(chatCompletionCalls == 2)
        #expect(oneShot == "Done")
    }
}
