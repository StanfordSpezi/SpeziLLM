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
 
> Important: In order to use the LLM local target, one needs to set build parameters in the consuming Xcode project or the consuming SPM package to enable the [Swift / C++ Interop](https://www.swift.org/documentation/cxx-interop/), introduced in Xcode 15 and Swift 5.9. Keep in mind that this is true for nested dependencies, one needs to set this configuration recursivly for the entire dependency tree towards the llama.cpp SPM package.  <!-- markdown-link-check-disable-line -->
> 
> **For Xcode projects:**
> - Open your [build settings in Xcode](https://developer.apple.com/documentation/xcode/configuring-the-build-settings-of-a-target/) by selecting *PROJECT_NAME > TARGET_NAME > Build Settings*.
> - Within the *Build Settings*, search for the `C++ and Objective-C Interoperability` setting and set it to `C++ / Objective-C++`. This enables the project to use the C++ headers from llama.cpp.
> 
> **For SPM packages:**
> - Open the `Package.swift` file of your [SPM package]((https://www.swift.org/documentation/package-manager/)) <!-- markdown-link-check-disable-line -->
> - Within the package `target` that consumes the llama.cpp package, add the `interoperabilityMode(_:)` Swift build setting like that:
> ```swift
> /// Adds the dependency to the Spezi LLM SPM package
> dependencies: [
>     .package(url: "https://github.com/StanfordSpezi/SpeziLLM", .upToNextMinor(from: "0.6.0"))
> ],
> targets: [
>   .target(
>       name: "ExampleConsumingTarget",
>       /// State the dependence of the target to SpeziLLMLocal
>       dependencies: [
>           .product(name: "SpeziLLMLocal", package: "SpeziLLM")
>       ],
>       /// Important: Configure the `.interoperabilityMode(_:)` within the `swiftSettings`
>       swiftSettings: [
>           .interoperabilityMode(.Cxx)
>       ]
>   )
> ]
>```

## Spezi LLM Local Components

The core components of the ``SpeziLLMLocal`` target are ``LLMLocalSchema``, ``LLMLocalSession`` as well as ``LLMLocalPlatform``. They heavily utilize the [llama.cpp library](https://github.com/ggerganov/llama.cpp) to perform the inference of the Language Model. ``LLMLocalSchema`` defines the type and configuration of the LLM, ``LLMLocalSession`` represents the ``LLMLocalSchema`` in execution while ``LLMLocalPlatform`` is the LLM execution platform.

> Important: To execute a LLM locally, the model file must be present on the local device. 
> The model must be in the popular `.gguf` format introduced by the [llama.cpp library](https://github.com/ggerganov/llama.cpp)

> Tip: In order to download the model file of the Language model to the local device, SpeziLLM provides the [SpeziLLMLocalDownload](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillmlocaldownload) target which provides model download and storage functionalities.

``LLMLocalSchema`` offers a variety of configuration possibilities, such as the used model file, the context window, the maximum output size or the batch size. These options can be set via the ``LLMLocalSchema/init(modelPath:parameters:contextParameters:samplingParameters:injectIntoContext:formatChat:)`` initializer and the ``LLMLocalParameters``, ``LLMLocalContextParameters``, and ``LLMLocalSamplingParameters`` types. Keep in mind that the model file must be in the popular `.gguf` format!

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
                        modelPath: URL(string: "URL to the local model file")!
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

## Topics

### LLM Local abstraction

- ``LLMLocalSchema``
- ``LLMLocalSession``

### LLM Execution

- ``LLMLocalPlatform``
- ``LLMLocalPlatformConfiguration``

### LLM Configuration

- ``LLMLocalParameters``
- ``LLMLocalContextParameters``
- ``LLMLocalSamplingParameters``

### Misc

- ``LLMLocalError``
