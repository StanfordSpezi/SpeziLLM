# ``SpeziLLMLocal``

<!--
#
# This source file is part of the Stanford Spezi open source project
#
# SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
#
# SPDX-License-Identifier: MIT
#       
-->

Provides local Language Model execution capabilities on-device.

## Overview


The ``SpeziLLMLocal`` target enables the usage of locally executed Language Models (LLMs) directly on-device, without the need for any kind of internet connection and no data every leaving the local device. The underlying technology used for the LLM inference is [`mlx-swift`](https://github.com/ml-explore/mlx-swift). ``SpeziLLMLocal`` provides a pure Swift-based API for interacting with the locally executed model, building on top of the infrastructure of the [SpeziLLM target](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm).

## Setup

### Add Spezi LLM as a Dependency

You need to add the SpeziLLM Swift package to
[your app in Xcode](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app#) or
[Swift package](https://developer.apple.com/documentation/xcode/creating-a-standalone-swift-package-with-xcode#Add-a-dependency-on-another-Swift-package).

> Important: If your application is not yet configured to use Spezi, follow the [Spezi setup article](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/initial-setup) to set up the core Spezi infrastructure.
 
> Important: Spezi LLM Local is not compatible with simulators. The underlying [`mlx-swift`](https://github.com/ml-explore/mlx-swift) requires a modern Metal MTLGPUFamily and the simulator does not provide that.

> Important: To use the LLM local target, some LLMs require adding the *Increase Memory Limit* entitlement to the project.

## Spezi LLM Local Components

The core components of the ``SpeziLLMLocal`` target are ``LLMLocalSchema``, ``LLMLocalSession`` as well as ``LLMLocalPlatform``. They heavily utilize [mlx-swift-examples](https://github.com/ml-explore/mlx-swift-examples) to perform the inference of the Language Model. ``LLMLocalSchema`` defines the type and configuration of the LLM, ``LLMLocalSession`` represents the ``LLMLocalSchema`` in execution while ``LLMLocalPlatform`` is the LLM execution platform.

> Important: To execute a LLM locally, the model file must be present on the local device.

> Tip: In order to download the model file of the Language model to the local device, SpeziLLM provides the [SpeziLLMLocalDownload](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillmlocaldownload) target which provides model download and storage functionalities.

``LLMLocalSchema`` offers a variety of configuration possibilities, such as the used model file, the context window, the maximum output size or the batch size. These options can be set via the ``LLMLocalSchema/init(model:parameters:samplingParameters:injectIntoContext:)`` initializer and the ``LLMLocalParameters``, and ``LLMLocalSamplingParameters`` types.

- Important: ``LLMLocalSchema``, ``LLMLocalSession`` as well as ``LLMLocalPlatform`` shouldn't be used on it's own but always used together with the Spezi `LLMRunner`!

### Setup

In order to use local LLMs within Spezi, the [SpeziLLM](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm) [`LLMRunner`](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm/llmrunner) needs to be initialized in the Spezi `Configuration` with the ``LLMLocalPlatform``. Only after, the `LLMRunner` can be used to execute LLMs locally.
See the [SpeziLLM documentation](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm) for more details.

```swift
class LocalLLMAppDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration {
            LLMRunner {
                LLMLocalPlatform()
            }
        }
    }
}
```

### Usage

The code example below showcases the interaction with the local LLM abstractions through the the [SpeziLLM](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm) [`LLMRunner`](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm/llmrunner), which is injected into the SwiftUI `Environment` via the `Configuration` shown above.

The ``LLMLocalSchema`` defines the type and configurations of the to-be-executed ``LLMLocalSession``. This transformation is done via the [`LLMRunner`](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm/llmrunner) that uses the ``LLMLocalPlatform``. The inference via ``LLMLocalSession/generate()`` returns an `AsyncThrowingStream` that yields all generated `String` pieces.

The ``LLMLocalSession`` contains the ``LLMLocalSession/context`` property which holds the entire history of the model interactions. This includes the system prompt, user input, but also assistant responses.
Ensure the property always contains all necessary information, as the ``LLMLocalSession/generate()`` function executes the inference based on the ``LLMLocalSession/context``.

> Important: The local LLM abstractions should only be used together with the [SpeziLLM](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm) [`LLMRunner`](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm/llmrunner)!

```swift
struct LLMLocalDemoView: View {
    @Environment(LLMRunner.self) var runner
    @State var responseText = ""

    var body: some View {
        Text(responseText)
            .task {
                // Instantiate the `LLMLocalSchema` to an `LLMLocalSession` via the `LLMRunner`.
                let llmSession: LLMLocalSession = runner(
                    with: LLMLocalSchema(
                        model: .llama3_1_8B_4bit
                    )
                )

                do {
                    for try await token in try await llmSession.generate() {
                        responseText.append(token)
                    }
                } catch {
                    // Handle errors here. E.g., you can use `ViewState` and `viewStateAlert` from SpeziViews.
                }
            }
    }
}
```

### Offloading

To optimize inference performance and minimize resource consumption within the application, use the ``LLMLocalSession/offload()`` method. This function unloads the model from memory, thereby freeing up system resources when the model is not actively in use.
When further interaction with the model is required, calling either ``LLMLocalSession/setup()`` or ``LLMLocalSession/generate()`` will automatically reload the model into memory as needed.

## Topics

### LLM Local abstraction

- ``LLMLocalSchema``
- ``LLMLocalSession``

### LLM Execution

- ``LLMLocalPlatform``
- ``LLMLocalPlatformConfiguration``

### LLM Configuration

- ``LLMLocalParameters``
- ``LLMLocalSamplingParameters``

### Misc

- ``LLMLocalError``
