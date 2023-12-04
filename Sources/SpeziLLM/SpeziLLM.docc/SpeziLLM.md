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

The two main components of ``SpeziLLM`` are the ``LLM`` abstraction as well as the ``LLMRunner`` execution capability. The following section highlights the usage of these parts.

### LLM abstraction

``SpeziLLM`` provides the ``LLM`` protocol which provides an abstraction of an arbitrary Language Model, regardless of the execution locality (local or remote) or the specific model type.
Developers can use the ``LLM`` protocol to conform their LLM interface implementations to a standard which is consistent throughout the Spezi ecosystem.
It is recommended that ``LLM`` should be used in conjunction with the [Swift Actor concept](https://developer.apple.com/documentation/swift/actor), meaning one should use the `actor` keyword (not `class`) for the implementation of the model component. The Actor concept provides guarantees regarding concurrent access to shared instances from multiple threads.

> Important: An ``LLM`` shouldn't be executed on it's own but always used together with the ``LLMRunner``.
> Please refer to the ``LLMRunner`` documentation for a complete code example.

#### Usage

An example conformance of the ``LLM`` looks like the code sample below (lots of details were omitted for simplicity).
The key point is the need to implement the ``LLM/setup(runnerConfig:)`` as well as the ``LLM/generate(prompt:continuation:)`` functions, whereas the ``LLM/setup(runnerConfig:)`` has an empty default implementation as not every ``LLMHostingType`` requires the need for a setup closure.

```swift
actor LLMTest: LLM {
    var type: LLMHostingType = .local
    var state: LLMState = .uninitialized

    func setup(/* */) async {}
    func generate(/* */) async {}
}
```

### LLM runner

The ``LLMRunner`` is a Spezi `Module` that handles the execution of Language Models in the Spezi ecosystem, regardless of their execution locality (local or remote) or the specific model type. A ``LLMRunner`` wraps a Spezi ``LLM`` during it's execution, handling all management overhead tasks of the models execution.

The runner manages a set of ``LLMGenerationTask``'s as well as the respective LLM execution backends in order to enable a smooth and efficient model execution.

#### Setup

The ``LLMRunner`` needs to be initialized in the Spezi `Configuration` with the ``LLMRunnerConfiguration`` as well as a set of ``LLMRunnerSetupTask``s as arguments.

```swift
class LocalLLMAppDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration {
            // Configure the runner responsible for executing LLMs
            LLMRunner(
                runnerConfig: .init(
                    taskPriority: .medium
                )
            ) {
                // Runner setup tasks conforming to `LLMRunnerSetupTask` protocol
                LLMLocalRunnerSetupTask()
            }
        }
    }
}
```

#### Usage

The code section below showcases a complete code example on how to use the ``LLMRunner`` in combination with a `LLMLlama` (locally executed Language Model) from the [SpeziLLMLocal](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillmlocal) target.

```swift
import SpeziLLMLocal
// ...

struct LocalLLMChatView: View {
   // The runner responsible for executing the local LLM.
   @Environment(LLMRunner.self) private var runner: LLMRunner

   // The locally executed LLM
   private let model: LLMLlama = .init(
        modelPath: ...
   )

   @State var responseText: String

   func executePrompt(prompt: String) {
        // Execute the query on the runner, returning a stream of outputs
        let stream = try await runner(with: model).generate(prompt: "Hello LLM!")

        for try await token in stream {
            responseText.append(token)
       }
   }
}
```

### LLM Chat View

The ``LLMChatView`` presents a basic chat view that enables users to chat with a Spezi ``LLM`` in a typical chat-like fashion. The input can be either typed out via the iOS keyboard or provided as voice input and transcribed into written text.
The ``LLMChatView`` takes an ``LLM`` instance as well as initial assistant prompt as arguments to configure the chat properly.

> Tip: The ``LLMChatView`` builds on top of the [SpeziChat package](https://swiftpackageindex.com/stanfordspezi/spezichat/documentation).
> For more details, please refer to the DocC documentation of the [`ChatView`](https://swiftpackageindex.com/stanfordspezi/spezichat/documentation/spezichat/chatview).

#### Usage

An example usage of the ``LLMChatView`` can be seen in the following example.
The example uses the ``LLMMock`` as the passed ``LLM`` instance in order to provide a default output generation stream.

```swift
struct LLMLocalChatTestView: View {
    var body: some View {
        LLMChatView(
            model: LLMMock(),
            initialAssistantPrompt: [
                .init(
                    role: .assistant,
                    content: "Hello!"
                )
            ]
        )
    }
}
```

## Topics

### Model

- ``LLM``
- ``LLMState``
- ``LLMError``
- ``LLMHostingType``

### Execution

- ``LLMRunner``
- ``LLMRunnerConfiguration``
- ``LLMGenerationTask``
- ``LLMRunnerSetupTask``

### Views

- ``LLMChatView``
