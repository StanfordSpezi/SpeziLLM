//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


/// The underlying `ViewModifier` of `View/disabled(if:)`.
private struct LLMChatViewDisabledModifier<L: LLMSession>: ViewModifier {
    let llm: L?
    
    
    func body(content: Content) -> some View {
        content
            .disabled(llm == nil)
    }
}


extension View {
    /// Disables the content block this modifier is attached to.
    ///
    /// Based on the optionality of the passed `LLMSession`, the content block this modifier is attached to is automatically disabled if the ``LLMSession`` is `nil`.
    ///
    /// ### Usage
    ///
    /// The code example below showcases how to use the `View/disabled(if:)` modifier to disable content based on the state of the ``LLMSession``.
    ///
    /// ```swift
    /// struct LLMDemoView: View {
    ///     @Environment(LLMRunner.self) var runner
    ///     @State var llmSession: LLMMockSession?
    ///
    ///     var body: some View {
    ///         VStack {
    ///             Button {
    ///                 // ...
    ///             } label: {
    ///                 Text("Start LLM inference")
    ///             }
    ///                 .disabled(if: llmSession)
    ///
    ///             Text(responseText)
    ///         }
    ///             .task {
    ///                 self.llmSession = runner(with: LLMMockSchema())
    ///             }
    ///     }
    /// }
    /// ```
    public func disabled<L: LLMSession>(if llm: L?) -> some View {
        modifier(
            LLMChatViewDisabledModifier(
                llm: llm
            )
        )
    }
}
