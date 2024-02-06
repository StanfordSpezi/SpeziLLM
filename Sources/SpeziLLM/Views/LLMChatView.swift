//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziChat
import SpeziViews
import SwiftUI


/// Basic chat view that enables users to interact with an LLM.
///
/// The input can be either typed out via the iOS keyboard or provided as voice input and transcribed into written text.
/// The ``LLMChatView`` takes an ``LLMSchema`` instance as parameter within the ``LLMChatView/init(schema:)``. The ``LLMSchema`` defines the type and properties of the LLM that will be used by the ``LLMChatView`` to generate responses to user prompts.
///
/// > Tip: The ``LLMChatView`` builds on top of the [SpeziChat package](https://swiftpackageindex.com/stanfordspezi/spezichat/documentation).
/// > For more details, please refer to the DocC documentation of the [`ChatView`](https://swiftpackageindex.com/stanfordspezi/spezichat/documentation/spezichat/chatview).
///
/// ### Usage
///
/// An example usage of the ``LLMChatView`` can be seen in the following example.
/// The example uses the ``LLMMockSchema`` to generate responses to user prompts.
///
/// ```swift
/// struct LLMLocalChatTestView: View {
///     var body: some View {
///         LLMChatView(
///             schema: LLMMockSchema()
///         )
///     }
/// }
/// ```
public struct LLMChatView<L: LLMSchema>: View {
    /// The ``LLMRunner`` is responsible for executing the ``LLMSchema`` by turning it into a ``LLMSession``.
    @Environment(LLMRunner.self) private var runner
    /// The ``LLMSchema`` that defines the type and properties of the used LLM.
    private let schema: L
    
    /// The LLM in execution, as defined by the ``LLMSchema``.
    @State private var llmSession: L.Platform.Session?
    /// Indicates if the input field is disabled.
    @MainActor private var inputDisabled: Bool {
        llmSession?.state.representation == .processing
    }

    
    public var body: some View {
        Group {
            if let llmSession {
                let contextBinding = Binding { llmSession.context } set: { llmSession.context = $0 }
                
                ChatView(
                    contextBinding,
                    disableInput: inputDisabled,
                    exportFormat: .pdf,
                    messagePendingAnimation: .automatic
                )
                    .onChange(of: llmSession.context) { oldValue, newValue in
                        // Once the user enters a message in the chat, send a request to the local LLM.
                        if oldValue.count != newValue.count,
                           let lastChat = newValue.last, lastChat.role == .user {
                            Task {
                                do {
                                    // Trigger an output generation based on the `LLMSession/context`.
                                    let stream = try await llmSession.generate()
                                    
                                    for try await token in stream {
                                        llmSession.context.append(assistantOutput: token)
                                    }
                                } catch let error as LLMError {
                                    llmSession.state = .error(error: error)
                                } catch {
                                    llmSession.state = .error(error: LLMDefaultError.unknown(error))
                                }
                            }
                        }
                    }
                        .viewStateAlert(state: llmSession.state)
            } else {
                ProgressView()
            }
        }
            .task {
                // Instantiate the `LLMSchema` to an `LLMSession` via the `LLMRunner`.
                self.llmSession = await runner(with: schema)
            }
    }
    

    /// Creates a ``LLMChatView`` that provides developers with a basic chat view to interact with a Spezi LLM.
    ///
    /// - Parameters:
    ///   - model: The ``LLMSchema`` that defines the to-be-used LLM to generate outputs based on user input.
    public init(schema: L) {
        self.schema = schema
    }
}


#Preview {
    LLMChatView(
        schema: LLMMockSchema()
    )
        .previewWith {
            LLMRunner {
                LLMMockPlatform()
            }
        }
}
