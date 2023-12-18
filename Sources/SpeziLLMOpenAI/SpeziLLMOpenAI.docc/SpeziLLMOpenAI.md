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
            ``LLMOpenAI``
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

The core component of the ``SpeziLLMOpenAI`` target is the ``LLMOpenAI`` class which conforms to the [`LLM` protocol of SpeziLLM](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm/llm). ``LLMOpenAI`` uses the OpenAI API to perform textual inference on the GPT-3.5 or GPT-4 models from OpenAI.

> Important: To utilize an LLM from OpenAI, an OpenAI API Key is required. Ensure that the OpenAI account associated with the key has enough resources to access the specified model as well as enough credits to perform the actual inference.

> Tip: In order to collect the OpenAI API Key or model type from the user, ``SpeziLLMOpenAI`` provides the ``LLMOpenAIAPITokenOnboardingStep`` and ``LLMOpenAIModelOnboardingStep`` views which can be used in the onboarding flow of the application.

``LLMOpenAI`` offers a variety of configuration possibilities that are supported by the OpenAI API, such as the model type, the system prompt, the temperature of the model, and many more. These options can be set via the ``LLMOpenAI/init(parameters:modelParameters:)`` initializer and the ``LLMOpenAIParameters`` and ``LLMOpenAIModelParameters``.

- Important: ``LLMOpenAI`` shouldn't be used on it's own but always wrapped by the Spezi `LLMRunner` as the runner handles all management overhead tasks.

### Setup

In order to use the ``LLMOpenAI``, the [SpeziLLM](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm) [`LLMRunner`](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm/llmrunner) needs to be initialized in the Spezi `Configuration`. Only after, the `LLMRunner` can be used to execute the ``LLMOpenAI``.
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

### Usage

The code example below showcases the interaction with the ``LLMOpenAI`` through the the [SpeziLLM](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm) [`LLMRunner`](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm/llmrunner).
Based on a `String` prompt, the `LLMGenerationTask/generate(prompt:)` method returns an `AsyncThrowingStream` which yields the inferred characters until the generation has completed.

> Tip: The model can be queried via the `LLMGenerationTask/generate()` and `LLMGenerationTask/generate(prompt:)` calls (returned from wrapping the ``LLMOpenAI`` in the `LLMRunner` from the [SpeziLLM](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm) target).
    The first method takes no input prompt at all but uses the current context of the model (so `LLM/context`) to query the model.
    The second takes a `String`-based input from the user and appends it to the  context of the model (so `LLM/context`) before querying the model.

> Important: The ``LLMOpenAI`` should only be used together with the [SpeziLLM](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm) [`LLMRunner`](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm/llmrunner)!

```swift
struct LLMOpenAIChatView: View {
    // The runner responsible for executing the OpenAI LLM.
    @Environment(LLMRunner.self) private var runner: LLMRunner

    // The OpenAI LLM
    private let model: LLMOpenAI = .init(
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

### Onboarding Flow

The ``LLMOpenAIAPITokenOnboardingStep`` provides a view that can be used for the user to enter an OpenAI API key during onboarding in your Spezi application. The example below showcases of how to can add an OpenAI onboarding step within an application created from the Spezi Template Application below.

First, create a new view to show the onboarding step:

```swift
import SpeziOnboarding
import SpeziLLMOpenAI
import SwiftUI


struct OpenAIAPIKey: View {
    @EnvironmentObject private var onboardingNavigationPath: OnboardingNavigationPath
    
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
import SpeziLLMOpenAI
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

### Model

- ``LLMOpenAI``

### Configuration

- ``LLMOpenAIParameters``
- ``LLMOpenAIModelParameters``

### Setup

- ``LLMOpenAIRunnerSetupTask``

### Onboarding

- ``LLMOpenAIAPITokenOnboardingStep``
- ``LLMOpenAIModelOnboardingStep``
