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


/// Presents a basic chat view that enables users to chat with a Spezi ``LLM`` in a typical chat-like fashion.
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
public struct LLMChatView: View {
    /// A ``LLMRunner`` is responsible for executing the ``LLM``. Must be configured via the Spezi `Configuration`.
    @Environment(LLMRunner.self) private var runner
    /// A SpeziLLM ``LLM`` that is used for the text generation within the chat view
    @State private var model: any LLM
    
    
    /// Indicates if the input field is disabled.
    @MainActor var inputDisabled: Bool {
        model.state.representation == .processing
    }
    
    public var body: some View {
        ChatView($model.context, disableInput: inputDisabled)
            .onChange(of: model.context) { oldValue, newValue in
                /// Once the user enters a message in the chat, send a request to the local LLM.
                if oldValue.count != newValue.count,
                   let lastChat = newValue.last, lastChat.role == .user {
                    Task {
                        do {
                            let stream = try await runner(with: model).generate()
                            
                            for try await token in stream {
                                model.context.append(assistantOutput: token)
                            }
                        } catch let error as LLMError {
                            model.state = .error(error: error)
                        } catch {
                            model.state = .error(error: LLMRunnerError.setupError)
                        }
                    }
                }
            }
                .viewStateAlert(state: model.state)
    }
    
    
    /// Creates a ``LLMChatView`` that provides developers with a basic chat view towards a SpeziLLM ``LLM``.
    ///
    /// - Parameters:
    ///   - model: The SpeziLLM ``LLM`` that should be used for the text generation.
    public init(
        model: any LLM
    ) {
        self._model = State(wrappedValue: model)
    }
}


#Preview {
    LLMChatView(
        model: LLMMock()
    )
}
