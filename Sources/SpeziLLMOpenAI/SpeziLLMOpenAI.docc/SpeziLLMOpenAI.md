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

> Note:
SpeziLLMOpenAI is implemented in an API-provider-agnostic way, in order to enable support for other APIs that provide compatibility layers over OpenAI's API (e.g., Anthropic and Gemini).
In effect, this means that some parts of the SpeziLLMOpenAI infrastructure are defined as abstractions (e.g., ``LLMOpenAILikeSession``) which are generic over a ``LLMOpenAILikePlatformDefinition``, and then have a corresponding specialized, OpenAI-specific version (e.g., ``LLMOpenAISession``).
Unless you with to integrate additional third-party LLM inference providers into SpeziLLM (see <doc:#Non-OpenAI-Inference-Providers>), you can ignore the `LLMOpenAILike` types and use only the OpenAI-specific specializations.


### Spezi LLM OpenAI Components

The core components of the ``SpeziLLMOpenAI`` target are the ``LLMOpenAISchema``, ``LLMOpenAISession`` as well as ``LLMOpenAIPlatform``.

> Important:
To utilize an LLM from OpenAI, an OpenAI API Key is required.
Also, note that OpenAI [explicitly advise against hardcoding API keys into apps](https://help.openai.com/en/articles/5112595-best-practices-for-api).

### LLM OpenAI

``LLMOpenAISchema`` offers a variety of configuration possibilities that are supported by the OpenAI API, such as the model type, the system prompt, the temperature of the model, and many more.
These options can be set via the ``LLMOpenAILikeSchema/init(parameters:modelParameters:injectIntoContext:_:)`` initializer and the ``LLMOpenAIParameters`` and ``LLMOpenAIModelParameters``.

- Important: The OpenAI LLM abstractions shouldn't be used on their own, but always used together with the Spezi `LLMRunner`.

### Setup

In order to use OpenAI LLMs, a [SpeziLLM](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm) [`LLMRunner`](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm/llmrunner) needs to be initialized in the Spezi `Configuration` with the ``LLMOpenAIPlatform``.
Only after, the `LLMRunner` can be used to do inference via OpenAI LLMs.
See the [SpeziLLM documentation](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm) for more details.

```swift
import Spezi
import SpeziLLM
import SpeziLLMOpenAI

class AppDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration {
            LLMRunner {
                LLMOpenAIPlatform(configuration: .init(
                    authToken: .keychain(for: OpenAIPlatformDefinition.self)
                    // ... additional options if you desire
                ))
            }
        }
    }
}
```


### Usage

The code example below showcases the interaction with the OpenAI LLMs within the Spezi ecosystem through the the [SpeziLLM](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm) [`LLMRunner`](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm/llmrunner), which is injected into the SwiftUI `Environment` via the `Configuration` shown above.

The ``LLMOpenAISchema`` defines the type and configurations of the to-be-executed ``LLMOpenAISession``.
This transformation is done via the [`LLMRunner`](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm/llmrunner) that uses the ``LLMOpenAIPlatform``. The inference via ``LLMOpenAILikeSession/generate()`` returns an `AsyncThrowingStream` that yields all generated `String` pieces.

The ``LLMOpenAISession`` contains the ``LLMOpenAILikeSession/context`` property which holds the entire history of the model interactions. This includes the system prompt, user input, but also assistant responses.
Ensure the property always contains all necessary information, as the ``LLMOpenAILikeSession/generate()`` function executes the inference based on the ``LLMOpenAILikeSession/context``

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
                // Use the LLMRunner to obtain an LLMOpenAISession, for a schema. 
                let llmSession: LLMOpenAISession = runner(
                    with: LLMOpenAISchema(
                        parameters: .init(
                            modelType: .gpt4o,
                            systemPrompt: "You're a helpful assistant that answers questions from users."
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


### LLM Function Calling

The OpenAI GPT-based LLMs provide function calling capabilities in order to enable a structured, bidirectional, and reliable communication between the OpenAI LLMs and external tools, such as the Spezi ecosystem.
``SpeziLLMOpenAI`` provides a declarative Domain Specific Language to make LLM function calling as seamless as possible within Spezi.
An extensive documentation can be found in <doc:FunctionCalling>.


### Onboarding Integration

For apps that require user-supplied API keys (as opposed to routing requests through a custom backend server), SpeziLLMOpenAI offers dedicated onboarding UI, for collecting an API key from the user, and allowing the user to select a model.
Such user-collected API keys are securely stored in the iOS system keychain, until the user provides a new key or it is cleared by the application.



### Non-OpenAI Inference Providers

SpeziLLMOpenAI's core infrastructure is implemented in an API provider-agnostic manner, enabling it to be used with any LLM inference provider that offers a compatibility layer over the OpenAI API.
This is for example how SpeziLLM's Anthropic and Gemini support is implemented.

In order to add support for an additional LLM provider, you need to define a ``LLMOpenAILikePlatformDefinition``, and define convenience typealiases specializing the various types:

```swift
import SpeziLLMOpenAI

struct MistralPlatformDefinition: LLMOpenAILikePlatformDefinition {
    struct ModelType: LLMOpenAILikePlatformModelType {
        let modelId: String
        var apiMode: LLMOpenAIAPIMode { .chatCompletions }
    }
    static let platformName: String = "Mistral"
    static let defaultServerUrl = URL(string: "https://api.mistral.ai/v1")!
    static let platformServiceIdentifier: String = "api.mistral.ai"
}

extension MistralPlatformDefinition.ModelType {
    static let `default`: Self = .small_latest
    static let wellKnownModels: [Self] = [.small_latest]
    
    static let small_latest = Self(modelId: "mistral-small-latest")
}

typealias MistralLLMPlatform = LLMOpenAILikePlatform<MistralPlatformDefinition>
typealias MistralLLMSchema = LLMOpenAILikeSchema<MistralPlatformDefinition>
typealias MistralLLMSession = LLMOpenAILikeSession<MistralPlatformDefinition>
```

You can now set up a `MistralLLMPlatform` in your SpeziLLM configuration, and use the Mistral API the same way you would the OpenAI ones.


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

### LLM Configuration
- ``LLMOpenAIParameters``
- ``LLMOpenAIModelParameters``

### Misc
- ``LLMOpenAIError``
