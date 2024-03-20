# ``SpeziLLM``

<!--
#
# This source file is part of the Stanford Spezi open source project
#
# SPDX-FileCopyrightText: 2023 Stanford University and the project authors (see CONTRIBUTORS.md)
#
# SPDX-License-Identifier: MIT
#       
-->

Provides base Large Language Model (LLM) execution infrastructure within the Spezi ecosystem.

## Overview

The ``SpeziLLM`` target provides the base infrastructure for Large Language Model (LLM) execution within the Swift-based Spezi ecosystem. It contains necessary abstractions of LLMs that can be reused in an arbitrary context as well as a runner component handling the actual inference of the Language Model.

## Setup

### Add Spezi LLM as a Dependency

You need to add the SpeziLLM Swift package to
[your app in Xcode](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app#) or
[Swift package](https://developer.apple.com/documentation/xcode/creating-a-standalone-swift-package-with-xcode#Add-a-dependency-on-another-Swift-package).

> Important: If your application is not yet configured to use Spezi, follow the [Spezi setup article](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/initial-setup) to set up the core Spezi infrastructure.

## Spezi LLM Components

The two main components of ``SpeziLLM`` are the LLM abstractions which are composed of the ``LLMSchema``, ``LLMSession``, and ``LLMPlatform`` as well as the ``LLMRunner`` execution capability. The following section highlights the usage of these parts.

### LLM abstractions

``SpeziLLM`` provides three main parts abstracting LLMs:
- ``LLMSchema``: Configuration of the to-be-used LLM, containing all information necessary for the creation of an executable ``LLMSession``.
- ``LLMSession``: Executable version of the LLM containing context and state as defined by the ``LLMSchema``.
- ``LLMPlatform``: Responsible for turning the received ``LLMSchema`` to an executable ``LLMSession``.

These protocols provides an abstraction layer for the usage of Large Language Models within the Spezi ecosystem,
regardless of the execution locality (local or remote) or the specific model type.
Developers can use these protocols to conform their LLM interface implementations to a standard which is consistent throughout the Spezi ecosystem.

The actual inference logic as well as state is held within the ``LLMSession``. It requires implementation of the ``LLMSession/generate()`` as well as ``LLMSession/cancel()`` functions, starting and cancelling the inference by the LLM respectively.
In addition, it contains the ``LLMSession/context`` in which the entire conversational history with the LLM is held as well as the ``LLMSession/state`` describing the current execution state of the session. 

> Important: Any of the three aforementioned LLM abstractions shouldn't be used on it's own but always together with the ``LLMRunner``.
    Please refer to the ``LLMRunner`` documentation for a complete code example.

### LLM runner

The ``LLMRunner`` is a Spezi `Module` accessible via the SwiftUI `Environment` that handles the execution of Language Models in the Spezi ecosystem, regardless of their execution locality (represented by the ``LLMPlatform``) or the specific model type. 
A ``LLMRunner`` is responsible for turning a ``LLMSchema`` towards an executable and stateful ``LLMSession`` by using the underlying ``LLMPlatform``.

The ``LLMRunner`` is configured with the supported ``LLMPlatform``s, enabling the runner to delegate the LLM execution to the correct ``LLMPlatform``.

#### Setup

Before usage, the ``LLMRunner`` needs to be initialized in the Spezi `Configuration` with the supported ``LLMPlatform``s.

```swift
class LocalLLMAppDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration {
            // Configure the runner responsible for executing LLMs.
            LLMRunner {
                // State the `LLMPlatform`s supported by the `LLMRunner`.
                LLMMockPlatform()
            }
        }
    }
}
```

#### Usage

The code section below showcases a complete, bare-bone code example on how to use the ``LLMRunner`` with the ``LLMSchema``.
The example is structured as a SwiftUI `View` with a `Button` to trigger LLM inference via the ``LLMMockSchema``. The generated output stream is displayed in a `Text` field.

- Tip: SpeziLLM provides the `@LLMSessionProvider` property wrapper (`View/LLMSessionProvider`) that drastically simplifies the state management of using the ``LLMSchema`` with the ``LLMRunner``. Refer to the docs below for more information.

```swift
struct LLMDemoView: View {
    // The runner responsible for executing the LLM.
    @Environment(LLMRunner.self) var runner

    // The LLM in execution, as defined by the ``LLMSchema``.
    @State var llmSession: LLMMockSession?
    @State var responseText = ""

    var body: some View {
        VStack {
            Button {
                Task {
                    try await executePrompt(prompt: "Hello LLM!")
                }
            } label: {
                Text("Start LLM inference")
            }
                .disabled(if: llmSession)

            Text(responseText)
        }
            .task {
                // Instantiate the `LLMSchema` to an `LLMSession` via the `LLMRunner`.
                self.llmSession = runner(with: LLMMockSchema())
            }
    }

    func executePrompt(prompt: String) async throws {
        await MainActor.run {
            llmSession?.context.append(userInput: prompt)
        }

        // Performing the LLM inference, returning a stream of outputs.
        guard let stream = try await llmSession?.generate() else {
            return
        }

        for try await token in stream {
            responseText.append(token)
        }
   }
}
```

As show in the example above, a simple LLM inference task with the ``LLMSession`` quickly becomes complex.
That's why SpeziLLM provides the `@LLMSessionProvider` property wrapper (`View/LLMSessionProvider`) that enables the convenient instantiation of the passed ``LLMSchema`` (defining the LLM) to a to-be-used ``LLMSession`` (LLM in execution).
The instantiation is done by the ``LLMRunner`` which determines the correct ``LLMPlatform`` for the ``LLMSchema`` to run on.
An example of using the `@LLMSessionProvider` property wrapper can be found below:

```swift
struct LLMDemoView: View {
    // Use the convenience property wrapper to instantiate the `LLMMockSession`
    @LLMSessionProvider(schema: LLMMockSchema()) var llm: LLMMockSession
    @State var responseText = ""

    var body: some View {
        VStack {
            Button {
                Task { @MainActor in
                    llm.context.append(userInput: "Hello!")

                    for try await token in try await llm.generate() {
                        responseText.append(token)
                    }
                }
            } label: {
                Text("Start LLM inference")
            }
                .disabled(llm.state.representation == .processing)

            Text(responseText)
        }
    }
}
```

### LLM Chat View

The ``LLMChatView`` and ``LLMChatViewSchema`` present a basic chat views that enables users to chat with a Spezi LLM in a typical chat-like fashion. The input can be either typed out via the iOS keyboard or provided as voice input and transcribed into written text.
The ``LLMChatViewSchema`` takes an ``LLMSchema`` instance to define which LLM in what configuration should be used for the text inference.
The ``LLMChatView`` is passed an ``LLMSession`` that represents the LLM in execution containing state and context, and an optional `ChatView/ChatExportFormat` that defines the format of the to-be-exported `SpeziChat/Chat` (can be any of `.pdf`, `.text`, `.json`, or `.none`, defaults to `.pdf`).

> Tip: The ``LLMChatView`` and ``LLMChatViewSchema`` build on top of the [SpeziChat package](https://swiftpackageindex.com/stanfordspezi/spezichat/documentation).
    For more details, please refer to the DocC documentation of the [`ChatView`](https://swiftpackageindex.com/stanfordspezi/spezichat/documentation/spezichat/chatview).

> Tip: By defuault, the ``LLMChatView`` presents a share button in the toolbar that exports the current `SpeziChat/Chat`. To remove this element and disable export functionality, pass `.none` for the `exportFormat` parameter in ``LLMChatView/init(session:exportFormat:)``.

#### Usage

An example usage of the ``LLMChatViewSchema`` can be seen in the following example.
The example uses the ``LLMMockSchema`` as the passed ``LLMSchema`` instance in order to provide a mock output generation stream.
Keep in mind that one cannot access the underlying context or state of the ``LLMSession`` when using the ``LLMChatViewSchema``.

```swift
struct LLMDemoChatView: View {
    var body: some View {
        LLMChatViewSchema(with: LLMMockSchema())
    }
}
```

An example of using the lower-level ``LLMChatView`` can be seen in the following example.
Here, the user has full control over the ``LLMSession`` and can access the context or state of the LLM.
SpeziLLM provides the `@LLMSessionProvider` property wrapper (`View/LLMSessionProvider`) that enables the convenient instantiation of the passed ``LLMSchema`` (defining the LLM) to a to-be-used ``LLMSession`` (LLM in execution).

```swift
struct LLMDemoChatView: View {
    // Use the convenience property wrapper to instantiate the `LLMMockSession`
    @LLMSessionProvider(schema: LLMMockSchema()) var llm: LLMMockSession

    var body: some View {
        LLMChatView(session: $llm)
    }
}
```

## Topics

### LLM abstraction

- ``LLMSchema``
- ``LLMSession``
- ``LLMState``
- ``LLMError``

### LLM Execution

- ``LLMRunner``
- ``LLMPlatform``

### Views

- ``LLMChatView``
- ``LLMChatViewSchema``

### Mocks

- ``LLMMockPlatform``
- ``LLMMockSchema``
- ``LLMMockSession``
