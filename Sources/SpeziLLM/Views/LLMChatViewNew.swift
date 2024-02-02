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


/// Basic chat view that enables users to chat with a Spezi ``LLM``.
///
/// The input can be either typed out via the iOS keyboard or provided as voice input and transcribed into written text.
/// The ``LLMChatView`` takes an ``LLM`` instance as well as initial assistant prompt as arguments to configure the chat properly.
///
/// > Tip: The ``LLMChatView`` builds on top of the [SpeziChat package](https://swiftpackageindex.com/stanfordspezi/spezichat/documentation).
/// > For more details, please refer to the DocC documentation of the [`ChatView`](https://swiftpackageindex.com/stanfordspezi/spezichat/documentation/spezichat/chatview).
///
/// ### Usage
///
/// An example usage of the ``LLMChatView`` can be seen in the following example.
/// The example uses the ``LLMMock`` as the passed ``LLM`` instance in order to provide a default output generation stream.
///
/// ```swift
/// struct LLMLocalChatTestView: View {
///     var body: some View {
///         LLMChatView(
///             model: LLMMock()
///         )
///     }
/// }
/// ```
public struct LLMChatViewNew<L: LLMSchema>: View {
    /// A ``LLMRunner`` is responsible for executing the ``LLM``. Must be configured via the Spezi `Configuration`.
    @Environment(LLMRunnerNew.self) private var runner
    /// A SpeziLLM ``LLM`` that is used for the text generation within the chat view
    private let schema: L
    
    @State private var llmSession: L.Platform.Session?
    
    /// Indicates if the input field is disabled.
    @MainActor var inputDisabled: Bool {
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
                        /// Once the user enters a message in the chat, send a request to the local LLM.
                        if oldValue.count != newValue.count,
                           let lastChat = newValue.last, lastChat.role == .user {
                            Task {
                                do {
                                    let stream = try await llmSession.generate()
                                    
                                    for try await token in stream {
                                        llmSession.context.append(assistantOutput: token)
                                    }
                                } catch let error as LLMError {
                                    llmSession.state = .error(error: error)
                                } catch {
                                    llmSession.state = .error(error: LLMRunnerError.setupError)
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
                self.llmSession = await runner(with: schema)
            }
    }
    

    /// Creates a ``LLMChatViewNew`` that provides developers with a basic chat view towards a SpeziLLM ``LLM``.
    ///
    /// - Parameters:
    ///   - model: The SpeziLLM ``LLM`` that should be used for the text generation.
    public init(schema: L) {
        self.schema = schema
    }
}


#Preview {
    LLMChatView(
        model: LLMMock()
    )
}
