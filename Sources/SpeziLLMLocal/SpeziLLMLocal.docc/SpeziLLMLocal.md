# ``SpeziLLMLocal``

<!--
#
# This source file is part of the Stanford Spezi open source project
#
# SPDX-FileCopyrightText: 2023 Stanford University and the project authors (see CONTRIBUTORS.md)
#
# SPDX-License-Identifier: MIT
#       
-->

Provides local Language Model execution capabilities on-device.

## Overview

The ``SpeziLLMLocal`` target enables the usage of locally executed Language Models (LLMs) directly on-device, without the need for any kind of internet connection and no data every leaving the local device. The underlying technology used for the LLM inference is [llama.cpp](https://github.com/ggerganov/llama.cpp), a C/C++ library for executing [LLaMa models](https://ai.meta.com/llama/). ``SpeziLLMLocal`` provides a pure Swift-based API for interacting with the locally executed model, building on top of the infrastructure of the [SpeziLLM target](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm).

## Setup

### Add Spezi LLM as a Dependency

You need to add the SpeziLLM Swift package to
[your app in Xcode](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app#) or
[Swift package](https://developer.apple.com/documentation/xcode/creating-a-standalone-swift-package-with-xcode#Add-a-dependency-on-another-Swift-package).

> Important: If your application is not yet configured to use Spezi, follow the [Spezi setup article](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/initial-setup) to set up the core Spezi infrastructure.

## Spezi LLM Local Components

The core component of the ``SpeziLLMLocal`` target is the ``LLMLlama`` [Actor](https://developer.apple.com/documentation/swift/actor) which conforms to the [`LLM` protocol of SpeziLLM](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm/llm). ``LLMLlama`` heavily utilizes the [llama.cpp library](https://github.com/ggerganov/llama.cpp) to perform the inference of the Language Model. 

> Important: To execute a LLM locally, ``LLMLlama`` requires the model file being present on the local device. 
> The model must be in the popular `.gguf` format introduced by the [llama.cpp library](https://github.com/ggerganov/llama.cpp)

> Tip: In order to download the model file of the Language model to the local device, SpeziLLM provides the [SpeziLLMLocalDownload](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillmlocaldownload) target which provides model download and storage functionalities.

``LLMLlama`` offers a variety of configuration possibilities, such as the used model file, the context window, the maximum output size or the batch size. These options can be set via the ``LLMLlama/init(modelPath:parameters:contextParameters:samplingParameters:)`` initializer and the ``LLMParameters``, ``LLMContextParameters``, and ``LLMSamplingParameters`` types. Keep in mind that the model file must be in the popular `.gguf` format!

- Important: ``LLMLlama`` shouldn't be used on it's own but always wrapped by the Spezi `LLMRunner` as the runner handles all management overhead tasks.

### Setup

In order to use the ``LLMLlama``, the [SpeziLLM](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm) [`LLMRunner`](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm/llmrunner) needs to be initialized in the Spezi `Configuration`. Only after, the `LLMRunner` can be used to execute the ``LLMLlama`` locally.
See the [SpeziLLM documentation](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm) for more details.

```swift
class LocalLLMAppDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration {
            LLMRunner(
                runnerConfig: .init(
                    taskPriority: .medium
                )
            ) {
                LLMLocalRunnerSetupTask()
            }
        }
    }
}
```

### Usage

The code example below showcases the interaction with the ``LLMLlama`` through the the [SpeziLLM](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm) [`LLMRunner`](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm/llmrunner).
Based on a `String` prompt, the `LLMGenerationTask/generate(prompt:)` method returns an `AsyncThrowingStream` which yields the inferred characters until the generation has completed.

> Important: The ``LLMLlama`` should only be used together with the [SpeziLLM](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm) [`LLMRunner`](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm/llmrunner)!

```swift
struct LocalLLMChatView: View {
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

## Topics

### Model

- ``LLMLlama``

### Configuration

- ``LLMParameters``
- ``LLMContextParameters``
- ``LLMSamplingParameters``

### Setup

- ``LLMLocalRunnerSetupTask``
