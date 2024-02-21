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
    private let schema: L?
    
    /// The LLM in execution, as defined by the ``LLMSchema``.
    @State private var llm: L.Platform.Session?
    @State private var muted = true
    
    /// Indicates if the input field is disabled.
    @MainActor private var inputDisabled: Bool {
        llm == nil || llm?.state.representation == .processing
    }
    @MainActor private var contextBinding: Binding<Chat> {
        Binding {
            llm?.context ?? []
        } set: {
            llm?.context = $0
        }
    }
    
    
    public var body: some View {
        ChatView(
            contextBinding,
            disableInput: inputDisabled,
            exportFormat: .pdf,
            messagePendingAnimation: .automatic
        )
            .speak(contextBinding.wrappedValue, muted: muted)
            .speechToolbarButton(muted: $muted)
            .viewStateAlert(state: llm?.state ?? .loading)
            .onChange(of: contextBinding.wrappedValue) { oldValue, newValue in
                // Once the user enters a message in the chat, send a generation request to the LLM.
                if oldValue.count != newValue.count,
                   let lastChat = newValue.last, lastChat.role == .user,
                   let llm {
                    Task {
                        do {
                            // Trigger an output generation based on the `LLMSession/context`.
                            let stream = try await llm.generate()
                            
                            for try await token in stream {
                                llm.context.append(assistantOutput: token)
                            }
                        } catch let error as LLMError {
                            llm.state = .error(error: error)
                        } catch {
                            llm.state = .error(error: LLMDefaultError.unknown(error))
                        }
                    }
                }
            }
            .task {
                // Instantiate the `LLMSchema` to an `LLMSession` via the `LLMRunner`.
                if let schema {
                    self.llm = await runner(with: schema)
                }
            }
    }
    

    /// Creates a ``LLMChatView`` that provides developers with a basic chat view to interact with a Spezi LLM.
    ///
    /// - Parameters:
    ///   - model: The ``LLMSchema`` that defines the to-be-used LLM to generate outputs based on user input.
    public init(schema: L) {
        self.schema = schema
    }
    
    public init(session: Binding<L.Platform.Session?>) {
        self.schema = nil
        self.llm = session.wrappedValue
    }
}


#Preview("LLMSchema") {
    LLMChatView(
        schema: LLMMockSchema()
    )
        .previewWith {
            LLMRunner {
                LLMMockPlatform()
            }
        }
}

#Preview("LLMSession") {
    @State var llm: LLMMockSession?
    
    // TODO: Remove generic type constraint
    return LLMChatView<LLMMockSchema>(
        session: $llm
    )
        .task {
            llm = LLMMockSession(.init(), schema: .init())
        }
        .previewWith {
            LLMRunner {
                LLMMockPlatform()
            }
        }
}
