//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


/// Refer to the documentation of ``View/LLMSessionProvider`` for information on how to use the `@LLMSessionProvider` property wrapper.
@propertyWrapper
public struct _LLMSessionProvider<Schema: LLMSchema>: DynamicProperty {     // swiftlint:disable:this type_name
    /// Internal boxing type required to wrap the ``LLMSession``.
    @Observable
    class Box<T> {
        var value: T

        init(_ value: T) {
            self.value = value
        }
    }
    
    
    /// The ``LLMRunner`` used to initialize the ``LLMSession``
    @Environment(LLMRunner.self) private var runner
    /// Boxed ``LLMSession`` `State`
    @State private var llmBox: Box<Schema.Platform.Session?>
    
    /// ``LLMSchema`` that defines the to-be-initialized ``LLMSession``.
    private let schema: Schema

    
    /// Access the initialized ``LLMSession``.
    public var wrappedValue: Schema.Platform.Session {
        guard let llm = llmBox.value else {
            fatalError("""
            The underlying LLMSession hasn't been initialized yet via the LLM Runner.
            Ensure that the @LLMSessionProvider is used within a SwiftUI View.
            """)
        }
        
        return llm
    }
    
    /// Creates a `Binding` to the ``LLMSession``that one can pass around. Useful for passing the ``LLMSession`` as a `Binding` to the ``LLMChatView``.
    @MainActor public var projectedValue: Binding<Schema.Platform.Session> {
        Binding {
            wrappedValue
        } set: {
            llmBox.value = $0
        }
    }
    
    
    /// Initialize the `_LLMSessionProvider` with the to be instantiated ``LLMSchema``.
    ///
    /// - Parameters:
    ///    - schema: The ``LLMSchema`` to instantiate as an ``LLMSession``.
    public init(schema: Schema) {
        self.schema = schema
        self._llmBox = State(wrappedValue: Box(nil))
    }
    
    
    /// Called by SwiftUI upon `View` update, initializes the ``LLMSession`` if not done yet.
    public func update() {
        guard llmBox.value == nil else {
            return
        }
        
        // Initialize `LLMSession` via `LLMRunner` from the SwiftUI `Environment`
        llmBox.value = runner(with: schema)
    }
}


extension View {
    /// Instantiates an ``LLMSession`` from the passed ``LLMSchema``.
    ///
    /// The ``LLMSessionProvider`` enables the convenient instantiation of the passed ``LLMSchema`` (defining the LLM) to a to-be-used ``LLMSession`` (LLM in execution).
    /// The instantiation is done by the ``LLMRunner`` which determines the correct ``LLMPlatform`` for the ``LLMSchema`` to run on.
    ///
    /// - Warning: To use the ``LLMSessionProvider``, the ``LLMRunner`` must be configured within the Spezi `Configuration`.
    ///
    /// ### Usage
    ///
    /// The example below demonstrates using the ``LLMSessionProvider`` to generate LLM output.
    ///
    /// ```swift
    /// struct LLMDemoView: View {
    ///     // Use the convenience property wrapper to instantiate the `LLMMockSession`
    ///     @LLMSessionProvider(schema: LLMMockSchema()) var llm: LLMMockSession
    ///     @State var responseText = ""
    ///
    ///     var body: some View {
    ///         VStack {
    ///             Button {
    ///                 Task { @MainActor in
    ///                     llm.context.append(userInput: "Hello!")
    ///
    ///                     for try await token in try await llm.generate() {
    ///                         responseText.append(token)
    ///                     }
    ///                 }
    ///             } label: {
    ///                 Text("Start LLM inference")
    ///             }
    ///                 .disabled(llm.state.representation == .processing)
    ///
    ///             Text(responseText)
    ///         }
    ///     }
    /// }
    /// ```
    public typealias LLMSessionProvider<Schema> = _LLMSessionProvider<Schema> where Schema: LLMSchema
}
