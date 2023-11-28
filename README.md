<!--
                  
This source file is part of the Stanford Spezi open source project

SPDX-FileCopyrightText: 2023 Stanford University and the project authors (see CONTRIBUTORS.md)

SPDX-License-Identifier: MIT
             
-->

# Spezi LLM

[![Build and Test](https://github.com/StanfordSpezi/SpeziLLM/actions/workflows/build-and-test.yml/badge.svg)](https://github.com/StanfordSpezi/SpeziLLM/actions/workflows/build-and-test.yml)
[![codecov](https://codecov.io/gh/StanfordSpezi/SpeziLLM/branch/main/graph/badge.svg?token=pptLyqtoNR)](https://codecov.io/gh/StanfordSpezi/SpeziLLM)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.7954213.svg)](https://doi.org/10.5281/zenodo.7954213)   <!-- TODO: Is this DOI still valid after the naming switch to SpeziLLM? -->
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FStanfordSpezi%2FSpeziLLM%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/StanfordSpezi/SpeziLLM)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FStanfordSpezi%2FSpeziLLM%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/StanfordSpezi/SpeziLLM)


# Overview

The Spezi LLM Swift Package includes modules that are helpful to integrate LLM-related functionality in your application.

# Spezi Open AI

A module that allows you to interact with GPT-based large language models (LLMs) from OpenAI within your Spezi application.

|<picture><source media="(prefers-color-scheme: dark)" srcset="Sources/SpeziLLMOpenAI/SpeziLLMOpenAI.docc/Resources/OpenAIAPIKeyOnboardingStep~dark.png"><img src="Sources/SpeziLLMOpenAI/SpeziLLMOpenAI.docc/Resources/OpenAIAPIKeyOnboardingStep.png" width="250" alt="Screenshot displaying the OpenAI API Key Onboarding view from Spezi OpenAI." /></picture>|<picture><source media="(prefers-color-scheme: dark)" srcset="Sources/SpeziLLMOpenAI/SpeziLLMOpenAI.docc/Resources/OpenAIModelSelectionOnboardingStep~dark.png"><img src="Sources/SpeziLLMOpenAI/SpeziLLMOpenAI.docc/Resources/OpenAIModelSelectionOnboardingStep.png" width="250" alt="Screenshot displaying the Open AI Model Selection Onboarding Step from Spezi OpenAI." /></picture>|<picture><source media="(prefers-color-scheme: dark)" srcset="Sources/SpeziLLMOpenAI/SpeziLLMOpenAI.docc/Resources/ChatView~dark.png"><img src="Sources/SpeziLLMOpenAI/SpeziLLMOpenAI.docc/Resources/ChatView.png" width="250" alt="Screenshot displaying the Chat View from Spezi OpenAI." /></picture>|
|:--:|:--:|:--:|
|`API Key Onboarding`|`Model Selection`|`Chat View`|


## Setup

### 1. Add Spezi LLM as a Dependency

First, you will need to add the SpeziLLM Swift package to
[your app in Xcode](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app#) or
[Swift package](https://developer.apple.com/documentation/xcode/creating-a-standalone-swift-package-with-xcode#Add-a-dependency-on-another-Swift-package). When adding the package, select the `SpeziLLMOpenAI` target to add.

### 2. Register the Open AI Module

> [!IMPORTANT]
> If your application is not yet configured to use Spezi, follow the [Spezi setup article](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/initial-setup) to set up the core Spezi infrastructure.

You can configure the `OpenAIModule` in the `SpeziAppDelegate` as follows.
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

The OpenAIModule injects an ``OpenAIModel`` in the SwiftUI environment to make it accessible thoughout your application.

```swift
class ExampleView: View {
    @Environment(OpenAIModel.self) var model


    var body: some View {
        // ...
    }
}
```

> [!NOTE]  
> The choice of model and API key are persisted across application launches. The `apiToken` and `openAIModel` can also be accessed and changed at runtime. 

The `SpeziLLMOpenAI` package also provides an `OpenAIAPIKeyOnboardingStep` that can be used to allow the user to provide their API key during the onboarding process instead (see `Examples` below). If using the `OpenAIAPIKeyOnboardingStep`, the `apiToken` property can be omitted here.


    var body: some View {
        // ...
    }
}
```

> [!NOTE]  
> You can learn more about a [`Module` in the Spezi documentation](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/module).

The `SpeziLLMOpenAI` package also provides an `OpenAIAPIKeyOnboardingStep` that can be used to allow the user to provide their API key during the onboarding process instead (see `Examples` below). If using the `OpenAIAPIKeyOnboardingStep`, the `apiToken` property can be omitted here.

> [!NOTE]  
> You can learn more about a [`Module` in the Spezi documentation](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/module).

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

For more information, please refer to the [API documentation](https://swiftpackageindex.com/StanfordSpezi/SpeziLLM/documentation).

## Contributing

Contributions to this project are welcome. Please make sure to read the [contribution guidelines](https://github.com/StanfordSpezi/.github/blob/main/CONTRIBUTING.md) and the [contributor covenant code of conduct](https://github.com/StanfordSpezi/.github/blob/main/CODE_OF_CONDUCT.md) first.


## License

This project is licensed under the MIT License. See [Licenses](https://github.com/StanfordSpezi/SpeziLLM/tree/main/LICENSES) for more information.

![Spezi Footer](https://raw.githubusercontent.com/StanfordSpezi/.github/main/assets/FooterLight.png#gh-light-mode-only)
![Spezi Footer](https://raw.githubusercontent.com/StanfordSpezi/.github/main/assets/FooterDark.png#gh-dark-mode-only)
