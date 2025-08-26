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

/// Chat view that enables users to interact with an LLM based on an ``LLMSession``.
///
/// The ``LLMChatView`` takes an ``LLMSession`` instance and an optional `ChatView/ChatExportFormat` as parameters within the ``LLMChatView/init(session:exportFormat:)``. The ``LLMSession`` is the executable version of the LLM containing context and state as defined by the ``LLMSchema``.
///
/// The input can be either typed out via the iOS keyboard or provided as voice input and transcribed into written text.
///
/// - Tip: The ``LLMChatView`` builds on top of the [SpeziChat package](https://swiftpackageindex.com/stanfordspezi/spezichat/documentation).
/// For more details, please refer to the DocC documentation of the [`ChatView`](https://swiftpackageindex.com/stanfordspezi/spezichat/documentation/spezichat/chatview).
///
/// - Tip: To add text-to-speech capabilities to the ``LLMChatView``, use the [SpeziChat package](https://swiftpackageindex.com/stanfordspezi/spezichat/documentation) and more specifically the `View/speak(_:muted:)` and `View/speechToolbarButton(enabled:muted:)` view modifiers.
/// For more details, please refer to the DocC documentation of the [`ChatView`](https://swiftpackageindex.com/stanfordspezi/spezichat/documentation/spezichat/chatview).
///
/// ### Usage
///
/// The next code examples demonstrate how to use the ``LLMChatView`` with ``LLMSession``s.
///
/// The ``LLMChatView`` must be passed a ``LLMSession``, meaning a ready-to-use LLM, resulting in the need for the developer to manually allocate the ``LLMSession`` via the ``LLMRunner`` and ``LLMSchema`` (which includes state management).
/// The ``LLMChatView`` may also be passed a `ChatView/ChatExportFormat` to enable the chat export functionality and define the format of the to-be-exported `SpeziChat/Chat`; possible export formats are `.pdf`, `.text`, and `.json`.
///
/// In order to simplify the usage of an ``LLMSession``, SpeziLLM provides the ``LLMSessionProvider`` property wrapper that conveniently instantiates an ``LLMSchema`` to an ``LLMSession``.
/// The `@LLMSessionProvider` wrapper abstracts away the necessity to use the ``LLMRunner`` from the SwiftUI `Environment` within a `.task()` view modifier to instantiate the ``LLMSession``.
/// In addition, state handling becomes easier, as one doesn't have to deal with the optionality of the ``LLMSession`` anymore.
///
/// In addition, one is able to use the  text-to-speech capabilities of [SpeziChat package](https://swiftpackageindex.com/stanfordspezi/spezichat/documentation) via the `View/speak(_:muted:)` and `View/speechToolbarButton(enabled:muted:)` view modifiers.
///
/// ```swift
/// struct LLMChatTestView: View {
///     // Use the convenience property wrapper to instantiate the `LLMMockSession`
///     @LLMSessionProvider(schema: LLMMockSchema()) var llm: LLMMockSession
///     @State var muted = true
///
///     var body: some View {
///         LLMChatView(session: $llm, exportFormat: .pdf)
///             .speak(llm.context, muted: muted)
///             .speechToolbarButton(muted: $muted)
///     }
/// }
/// ```
public struct LLMChatView<Session: LLMSession>: View {
    /// The LLM in execution, as defined by the ``LLMSchema``.
    @Binding private var llm: Session
    /// Tracks the latest message id.
    @State private var messageTaskIdentifier: Int?
    /// Indicates if the input field is disabled.
    @MainActor private var inputDisabled: Bool {
        llm.state.representation == .processing
    }
    /// Defines the export format of the to-be-exported `SpeziChat/Chat`
    private let exportFormat: ChatView.ChatExportFormat?


    public var body: some View {
        ChatView(
            self.$llm.context.chat,
            disableInput: self.inputDisabled,
            exportFormat: self.exportFormat,
            messagePendingAnimation: .automatic
        )
            .viewStateAlert(state: self.llm.state)
            .onChange(of: self.llm.context) { oldValue, newValue in
                // Once the user enters a message in the chat, increase `messageTaskIdentifier` that triggers LLM inference
                //
                // Checking `lastChat.complete == true` is a hack to differentiate user initiated messages (complete == true, default)
                // with user transcripts (when first appended: complete == false).
                if oldValue.count != newValue.count,
                   let lastChat = newValue.last, lastChat.role == .user, lastChat.complete == true {
                    self.messageTaskIdentifier = (self.messageTaskIdentifier ?? 0) + 1
                }
            }
            // Triggered on every new user message in the chat via `messageTaskIdentifier`
            // Automatically cancels the LLM inference once view disappears
            .task(id: self.messageTaskIdentifier) {
                // do not run on init of view
                guard self.messageTaskIdentifier != nil else {
                    return
                }
                
                do {
                    // Trigger an output generation based on the `LLMSession/context`.
                    let stream = try await self.llm.generate()
                    
                    if llm is any AudioCapableLLMSession {
                        // Return as AudioCapableLLMSessions append the result of `generate()` automatically to the `LLMContext`
                        return
                    }

                    for try await token in stream {
                        self.llm.context.append(assistantOutput: token)
                    }

                    self.llm.context.completeAssistantStreaming()
                } catch is CancellationError {
                    // noop
                } catch let error as any LLMError {
                    self.llm.state = .error(error: error)
                } catch {
                    self.llm.state = .error(error: LLMDefaultError.unknown(error))
                }
            }
    }


    /// Creates a ``LLMChatView`` with a `Binding` of a ``LLMSession`` that provides developers with a basic chat view to interact with a Spezi LLM.
    ///
    /// - Parameters:
    ///   - session: A `Binding` of a  ``LLMSession`` that contains the ready-to-use LLM to generate outputs based on user input.
    ///   - exportFormat: An optional `ChatView/ChatExportFormat` to enable the chat export functionality and define the format of the to-be-exported `SpeziChat/Chat`.
    public init(
        session: Binding<Session>,
        exportFormat: ChatView.ChatExportFormat? = nil
    ) {
        self._llm = session
        self.exportFormat = exportFormat
    }
}


#if DEBUG
#Preview {
    @Previewable @State var llm = LLMMockSession(.init(), schema: .init())


    return NavigationStack {
        LLMChatView(session: $llm)
            .speak(llm.context.chat, muted: true)
            .speechToolbarButton(muted: .constant(true))
            .previewWith {
                LLMRunner {
                    LLMMockPlatform()
                }
            }
    }
}
#endif
