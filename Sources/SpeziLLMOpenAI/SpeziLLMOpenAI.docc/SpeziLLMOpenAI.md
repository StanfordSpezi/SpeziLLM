# ``SpeziLLMOpenAI``

<!--
#
# This source file is part of the Stanford Spezi open source project
#
# SPDX-FileCopyrightText: 2023 Stanford University and the project authors (see CONTRIBUTORS.md)
#
# SPDX-License-Identifier: MIT
#       
-->

Interact with Large Language Models (LLMs) from OpenAI.

## Overview

A module that allows you to interact with GPT-based Large Language Models (LLMs) from OpenAI within your Spezi application.
``SpeziLLMOpenAI`` provides a pure Swift-based API for interacting with the OpenAI GPT API, building on top of the infrastructure of the [SpeziLLM target](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm).

@Row {
    @Column {
        @Image(source: "LLMOpenAIAPITokenOnboardingStep", alt: "Screenshot displaying the OpenAI API Token Onboarding view from Spezi OpenAI") {
            ``LLMOpenAIAPITokenOnboardingStep``
        }
    }
    @Column {
        @Image(source: "LLMOpenAIModelOnboardingStep", alt: "Screenshot displaying the Open AI Model Selection Onboarding Step"){
            ``LLMOpenAIModelOnboardingStep``
        }
    }
    @Column {
        @Image(source: "ChatView", alt: "Screenshot displaying the usage of the LLMOpenAI with the SpeziChat Chat View."){
            ``LLMOpenAISession``
        }
    }
}

## Setup

### Add Spezi LLM as a Dependency

You need to add the SpeziLLM Swift package to
[your app in Xcode](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app#) or
[Swift package](https://developer.apple.com/documentation/xcode/creating-a-standalone-swift-package-with-xcode#Add-a-dependency-on-another-Swift-package).

> Important: If your application is not yet configured to use Spezi, follow the [Spezi setup article](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/initial-setup) to set up the core Spezi infrastructure.

## Spezi LLM OpenAI Components

The core components of the ``SpeziLLMOpenAI`` target are the ``LLMOpenAISchema``, ``LLMOpenAISession`` as well as ``LLMOpenAIPlatform``. They heavily use the OpenAI API to perform textual inference on the GPT-3.5 or GPT-4 models from OpenAI.

> Important: To utilize an LLM from OpenAI, an OpenAI API Key is required. Ensure that the OpenAI account associated with the key has enough resources to access the specified model as well as enough credits to perform the actual inference.

> Tip: In order to collect the OpenAI API Key or model type from the user, ``SpeziLLMOpenAI`` provides the ``LLMOpenAIAPITokenOnboardingStep`` and ``LLMOpenAIModelOnboardingStep`` views which can be used in the onboarding flow of the application.

### LLM OpenAI

``LLMOpenAISchema`` offers a variety of configuration possibilities that are supported by the OpenAI API, such as the model type, the system prompt, the temperature of the model, and many more. These options can be set via the ``LLMOpenAISchema/init(parameters:modelParameters:injectIntoContext:_:)`` initializer and the ``LLMOpenAIParameters`` and ``LLMOpenAIModelParameters``.

- Important: The OpenAI LLM abstractions shouldn't be used on it's own but always used together with the Spezi `LLMRunner`.

#### Setup

In order to use OpenAI LLMs, the [SpeziLLM](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm) [`LLMRunner`](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm/llmrunner) needs to be initialized in the Spezi `Configuration` with the ``LLMOpenAIPlatform``. Only after, the `LLMRunner` can be used to do inference via OpenAI LLMs.
See the [SpeziLLM documentation](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm) for more details.

```swift
import Spezi
import SpeziLLM
import SpeziLLMOpenAI

class LLMOpenAIAppDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
         Configuration {
             LLMRunner {
                LLMOpenAIPlatform()
            }
        }
    }
}
```

#### Usage

The code example below showcases the interaction with the OpenAI LLMs within the Spezi ecosystem through the the [SpeziLLM](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm) [`LLMRunner`](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm/llmrunner), which is injected into the SwiftUI `Environment` via the `Configuration` shown above.

The ``LLMOpenAISchema`` defines the type and configurations of the to-be-executed ``LLMOpenAISession``. This transformation is done via the [`LLMRunner`](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm/llmrunner) that uses the ``LLMOpenAIPlatform``. The inference via ``LLMOpenAISession/generate()`` returns an `AsyncThrowingStream` that yields all generated `String` pieces.

The ``LLMOpenAISession`` contains the ``LLMOpenAISession/context`` property which holds the entire history of the model interactions. This includes the system prompt, user input, but also assistant responses.
Ensure the property always contains all necessary information, as the ``LLMOpenAISession/generate()`` function executes the inference based on the ``LLMOpenAISession/context``

```swift
import SpeziLLM
import SpeziLLMOpenAI
import SwiftUI

struct LLMOpenAIDemoView: View {
    @Environment(LLMRunner.self) var runner
    @State var responseText = ""

    var body: some View {
        Text(responseText)
            .task {
                // Instantiate the `LLMOpenAISchema` to an `LLMOpenAISession` via the `LLMRunner`.
                let llmSession: LLMOpenAISession = runner(
                    with: LLMOpenAISchema(
                        parameters: .init(
                            modelType: .gpt3_5Turbo,
                            systemPrompt: "You're a helpful assistant that answers questions from users.",
                            overwritingToken: "abc123"
                        )
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

#### LLM Function Calling

The OpenAI GPT-based LLMs provide function calling capabilities in order to enable a structured, bidirectional, and reliable communication between the OpenAI LLMs and external tools, such as the Spezi ecosystem.
``SpeziLLMOpenAI`` provides a declarative Domain Specific Language to make LLM function calling as seamless as possible within Spezi.
An extensive documentation can be found in <doc:FunctionCalling>.

### Onboarding Flow

The ``LLMOpenAIAPITokenOnboardingStep`` provides a view that can be used for the user to enter an OpenAI API key during onboarding in your Spezi application. The example below showcases of how to can add an OpenAI onboarding step within an application created from the Spezi Template Application below.

First, create a new view to show the onboarding step:

```swift
import SpeziLLMOpenAI
import SpeziOnboarding
import SwiftUI

struct OpenAIAPIKey: View {
    @Environment(OnboardingNavigationPath.self) private var onboardingNavigationPath: OnboardingNavigationPath
    
    var body: some View {
        LLMOpenAIAPITokenOnboardingStep {
            onboardingNavigationPath.nextStep()
        }
    }
}
```

This view can then be added to the `OnboardingFlow` within the Spezi Template Application:

```swift
import SpeziOnboarding
import SwiftUI

struct OnboardingFlow: View {
    @AppStorage(StorageKeys.onboardingFlowComplete) var completedOnboardingFlow = false
    
    var body: some View {
        OnboardingStack(onboardingFlowComplete: $completedOnboardingFlow) {
            // ... other steps
            OpenAIAPIKey()
            // ... other steps
        }
    }
}
```

Now the OpenAI API Key entry view will appear within your application's onboarding process. The API Key entered will be persisted across application launches.

## Topics

### LLM OpenAI abstraction

- ``LLMOpenAISchema``
- ``LLMOpenAISession``

### LLM Execution

- ``LLMOpenAIPlatform``
- ``LLMOpenAIPlatformConfiguration``

### Onboarding

- ``LLMOpenAIAPITokenOnboardingStep``
- ``LLMOpenAIModelOnboardingStep``
- ``LLMOpenAITokenSaver``
- ``LLMOpenAIModelType``

### LLM Configuration

- ``LLMOpenAIParameters``
- ``LLMOpenAIModelParameters``

### Misc

- ``LLMOpenAIError``
