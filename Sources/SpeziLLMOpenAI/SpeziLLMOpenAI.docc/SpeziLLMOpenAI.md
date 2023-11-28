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

A module that allows you to interact with GPT-based large language models (LLMs) from OpenAI within your Spezi application.

@Row {
    @Column {
        @Image(source: "OpenAIAPIKeyOnboardingStep", alt: "Screenshot displaying the OpenAI API Key Onboarding view from Spezi OpenAI") {
            ``OpenAIAPIKeyOnboardingStep``
        }
    }
    @Column {
        @Image(source: "OpenAIModelSelectionOnboardingStep", alt: "Screenshot displaying the Open AI Model Selection Onboarding Step"){
            ``OpenAIModelSelectionOnboardingStep``
        }
    }
    @Column {
        @Image(source: "ChatView", alt: "Screenshot displaying the usage of the OpenAIModule with the SpeziChat Chat View."){
            ``OpenAIModule``
        }
    }
}

## Setup

### 1. Add Spezi LLM as a Dependency

First, you will need to add the SpeziLLM Swift package to
[your app in Xcode](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app#) or
[Swift package](https://developer.apple.com/documentation/xcode/creating-a-standalone-swift-package-with-xcode#Add-a-dependency-on-another-Swift-package). When adding the package, select the `SpeziLLMOpenAI` target to add.

### 2. Register the Open AI Module

> Note: If your application is not yet configured to use Spezi, follow the [Spezi setup article](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/initial-setup) to set up the core Spezi infrastructure.

You can configure the ``OpenAIModule`` in the `SpeziAppDelegate` as follows.
In the example, we configure the `OpenAIModule` to use the GPT-4 model with a default API key.

```swift
import Spezi
import SpeziLLMOpenAI


class ExampleDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration {
            OpenAIModule(apiToken: "API_KEY", openAIModel: .gpt4)
        }
    }
}
```

The OpenAIModule injects an ``OpenAIModel`` in the SwiftUI environment to make it accessible throughout your application.

```swift
class ExampleView: View {
    @Environment(OpenAIModel.self) var model


    var body: some View {
        // ...
    }
}
```

> Tip: The choice of model and API key are persisted across application launches. The `apiToken` and `openAIModel` can also be accessed and changed at runtime. 

The `SpeziLLMOpenAI` package also provides an `OpenAIAPIKeyOnboardingStep` that can be used to allow the user to provide their API key during the onboarding process instead (see `Examples` below). If using the `OpenAIAPIKeyOnboardingStep`, the `apiToken` property can be omitted here.

> Tip: You can learn more about a [`Module` in the Spezi documentation](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/module).

## Examples

### Creating a Chat Interface

In this example, we will create a chat interface that allows the user to converse with the model. Responses from the model will be streamed.
To properly visualize the chat interface with the LLM, the example utilizes the [SpeziChat](https://github.com/StanfordSpezi/SpeziChat) module of the Spezi ecosystem, providing developers with easy to use chat interfaces like the `ChatView`.

```swift
import SpeziChat
import SpeziLLMOpenAI
import SwiftUI


struct OpenAIChatView: View {
    @Environment(OpenAIModel.self) var model
    @State private var chat: Chat = [
        .init(role: .assistant, content: "Assistant Message!")
    ]
    
    var body: some View {
        ChatView($chat)
            .onChange(of: chat) { _, _ in
                Task {
                    let chatStreamResults = try model.queryAPI(withChat: chat)
                    
                    for try await chatStreamResult in chatStreamResults {
                        for choice in chatStreamResult.choices {
                            guard let newContent = choice.delta.content else {
                                continue
                            }
                            
                            if chat.last?.role == .assistant, let previousContent = chat.last?.content {
                                await MainActor.run {
                                    chat[chat.count - 1] = ChatEntity(
                                        role: .assistant,
                                        content: previousContent + newContent
                                    )
                                }
                            } else {
                                await MainActor.run {
                                    chat.append(ChatEntity(role: .assistant, content: newContent))
                                }
                            }
                        }
                    }
                }
            }
    }
}
```

### Setting the API Key During Onboarding

The `OpenAIAPIKeyOnboardingStep` provides a view that can be used for the user to enter an OpenAI API key during onboarding in your Spezi application. We will show an example of how you can add an OpenAI onboarding step within an application created from the Spezi Template Application below.

First, create a new view to show the onboarding step:

```swift
import SpeziOnboarding
import SpeziLLMOpenAI
import SwiftUI


struct OpenAIAPIKey: View {
    @EnvironmentObject private var onboardingNavigationPath: OnboardingNavigationPath
    
    var body: some View {
        OpenAIAPIKeyOnboardingStep {
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
