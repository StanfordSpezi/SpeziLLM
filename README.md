<!--
                  
This source file is part of the Stanford Spezi open source project

SPDX-FileCopyrightText: 2023 Stanford University and the project authors (see CONTRIBUTORS.md)

SPDX-License-Identifier: MIT
             
-->

# Spezi LLM

[![Build and Test](https://github.com/StanfordSpezi/SpeziLLM/actions/workflows/build-and-test.yml/badge.svg)](https://github.com/StanfordSpezi/SpeziLLM/actions/workflows/build-and-test.yml)
[![codecov](https://codecov.io/gh/StanfordSpezi/SpeziLLM/branch/main/graph/badge.svg?token=pptLyqtoNR)](https://codecov.io/gh/StanfordSpezi/SpeziLLM)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.7954213.svg)](https://doi.org/10.5281/zenodo.7954213)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FStanfordSpezi%2FSpeziLLM%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/StanfordSpezi/SpeziLLM)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FStanfordSpezi%2FSpeziLLM%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/StanfordSpezi/SpeziLLM)


## Overview

The Spezi LLM Swift Package includes modules that are helpful to integrate LLM-related functionality in your application.
The package provides all necessary tools for local LLM execution as well as the usage of remote OpenAI-based LLMs.

|<picture><source media="(prefers-color-scheme: dark)" srcset="Sources/SpeziLLMOpenAI/SpeziLLMOpenAI.docc/Resources/ChatView~dark.png"><img src="Sources/SpeziLLMOpenAI/SpeziLLMOpenAI.docc/Resources/ChatView.png" width="250" alt="Screenshot displaying the Chat View utilizing the OpenAI API from SpeziLLMOpenAI." /></picture>|<picture><source media="(prefers-color-scheme: dark)" srcset="Sources/SpeziLLMLocalDownload/SpeziLLMLocalDownload.docc/Resources/LLMLocalDownload~dark.png"><img src="Sources/SpeziLLMLocalDownload/SpeziLLMLocalDownload.docc/Resources/LLMLocalDownload.png" width="250" alt="Screenshot displaying the Local LLM Download View from SpeziLLMLocalDownload." /></picture>|<picture><source media="(prefers-color-scheme: dark)" srcset="Sources/SpeziLLMLocal/SpeziLLMLocal.docc/Resources/ChatView~dark.png"><img src="Sources/SpeziLLMLocal/SpeziLLMLocal.docc/Resources/ChatView.png" width="250" alt="Screenshot displaying the Chat View utilizing a locally executed LLM via SpeziLLMLocal." /></picture>|
|:--:|:--:|:--:|
|`OpenAI LLM Chat View`|`Language Model Download`|`Local LLM Chat View`|

## Setup

### 1. Add Spezi LLM as a Dependency

You need to add the SpeziLLM Swift package to
[your app in Xcode](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app#) or
[Swift package](https://developer.apple.com/documentation/xcode/creating-a-standalone-swift-package-with-xcode#Add-a-dependency-on-another-Swift-package).

> [!IMPORTANT]  
> If your application is not yet configured to use Spezi, follow the [Spezi setup article](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/initial-setup) to set up the core Spezi infrastructure.

### 2. Follow the setup steps of the individual targets

As Spezi LLM contains a variety of different targets for specific LLM functionalities, please follow the additional setup guide in the respective target section of this README.

## Targets

Spezi LLM provides a number of targets to help developers integrate LLMs in their Spezi-based applications:
- [SpeziLLM](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm): Base infrastructure of LLM execution in the Spezi ecosystem.
- [SpeziLLMLocal](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillmlocal): Local LLM execution capabilities directly on-device. Enables running open-source LLMs like [Meta's Llama2 models](https://ai.meta.com/llama/).
- [SpeziLLMLocalDownload](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillmlocaldownload): Download and storage manager of local Language Models, including onboarding views. 
- [SpeziLLMOpenAI](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillmopenai): Integration with [OpenAIs GPT models](https://openai.com/gpt-4) via using OpenAIs API service.

The section below highlights the setup and basic use of the [SpeziLLMLocal](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillmlocal) and [SpeziLLMOpenAI](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillmopenai) targets in order to integrate Language Models in a Spezi-based application. 

> [!NOTE]  
> To learn more about the usage of the individual targets, please refer to the [DocC documentation of the package] (https://swiftpackageindex.com/stanfordspezi/spezillm/documentation).

### Spezi LLM Local

The target enables developers to easily execute medium-size Language Models (LLMs) locally on-device via the [llama.cpp framework](https://github.com/ggerganov/llama.cpp). The module allows you to interact with the locally run LLM via purely Swift-based APIs, no interaction with low-level C or C++ code is necessary, building on top of the infrastructure of the [SpeziLLM target](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm).

> [!IMPORTANT]  
> If one uses the `SpeziLLMLocal` target within an Xcode application, ensure to set the following ["Build Setting" of the respective target](https://developer.apple.com/documentation/xcode/configuring-the-build-settings-of-a-target/): `C++ and Objective-C interoperability` to `C++ / Objective-C++`. Otherwise, your application won't compile and you'll get complex compile error. 
> On the other hand, if one uses `SpeziLLMLocal` within an [SPM package](https://www.swift.org/documentation/package-manager/), ensure to properly set the `swiftSettings` of the respective target using `SpeziLLMLocal` to `swiftSettings: [.interoperabilityMode(.Cxx)]`.

#### Setup

You can configure the Spezi Local LLM execution within the typical `SpeziAppDelegate`.
In the example below, the `LLMRunner` from the [SpeziLLM](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm) target which is responsible for providing LLM functionality within the Spezi ecosystem is configured with the `LLMLocalRunnerSetupTask` from the [SpeziLLMLocal](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillmlocal) target. This prepares the `LLMRunner` to locally execute Language Models.

```
class TestAppDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration {
            LLMRunner {
                LLMLocalRunnerSetupTask()
            }
        }
    }
}
```

#### Usage

The code example below showcases the interaction with the `LLMLocal` through the the [SpeziLLM](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm) [`LLMRunner`](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm/llmrunner), which is injected into the SwiftUI `Environment` via the `Configuration` shown above..
Based on a `String` prompt, the `LLMGenerationTask/generate(prompt:)` method returns an `AsyncThrowingStream` which yields the inferred characters until the generation has completed.

```swift
struct LocalLLMChatView: View {
   @Environment(LLMRunner.self) var runner: LLMRunner

   // The locally executed LLM
   @State var model: LLMLocal = .init(
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

> [!NOTE]  
> To learn more about the usage of SpeziLLMLocal, please refer to the [DocC documentation]: (https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillmlocal).

### Spezi LLM Open AI

A module that allows you to interact with GPT-based Large Language Models (LLMs) from OpenAI within your Spezi application.
`SpeziLLMOpenAI` provides a pure Swift-based API for interacting with the OpenAI GPT API, building on top of the infrastructure of the [SpeziLLM target](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm).
In addition, `SpeziLLMOpenAI` provides developers with a declarative Domain Specific Language to utilize OpenAI function calling mechanism. This enables a structured, bidirectional, and reliable communication between the OpenAI LLMs and external tools, such as the Spezi ecosystem.

#### Setup

In order to use `LLMOpenAI`, the [SpeziLLM](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm) [`LLMRunner`](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm/llmrunner) needs to be initialized in the Spezi `Configuration`. Only after, the `LLMRunner` can be used to execute the ``LLMOpenAI``.
See the [SpeziLLM documentation](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm) for more details.

```swift
class LLMOpenAIAppDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
         Configuration {
             LLMRunner {
                LLMOpenAIRunnerSetupTask()
            }
        }
    }
}
```

#### Usage

The code example below showcases the interaction with the `LLMOpenAI` through the the [SpeziLLM](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm) [`LLMRunner`](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm/llmrunner), which is injected into the SwiftUI `Environment` via the `Configuration` shown above.
Based on a `String` prompt, the `LLMGenerationTask/generate(prompt:)` method returns an `AsyncThrowingStream` which yields the inferred characters until the generation has completed.

```swift
struct LLMOpenAIChatView: View {
    @Environment(LLMRunner.self) var runner: LLMRunner
    
    @State var model: LLMOpenAI = .init(
        parameters: .init(
            modelType: .gpt3_5Turbo,
            systemPrompt: "You're a helpful assistant that answers questions from users.",
            overwritingToken: "abc123"
        )
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

> [!NOTE]  
> To learn more about the usage of SpeziLLMOpenAI, please refer to the [DocC documentation] (https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillmopenai).

## Contributing

Contributions to this project are welcome. Please make sure to read the [contribution guidelines](https://github.com/StanfordSpezi/.github/blob/main/CONTRIBUTING.md) and the [contributor covenant code of conduct](https://github.com/StanfordSpezi/.github/blob/main/CODE_OF_CONDUCT.md) first.


## License

This project is licensed under the MIT License. See [Licenses](https://github.com/StanfordSpezi/SpeziLLM/tree/main/LICENSES) for more information.

![Spezi Footer](https://raw.githubusercontent.com/StanfordSpezi/.github/main/assets/FooterLight.png#gh-light-mode-only)
![Spezi Footer](https://raw.githubusercontent.com/StanfordSpezi/.github/main/assets/FooterDark.png#gh-dark-mode-only)
