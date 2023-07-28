# ``SpeziOpenAI``

<!--
#
# This source file is part of the Stanford Spezi open source project
#
# SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
#
# SPDX-License-Identifier: MIT
#       
-->

Module to interact with the OpenAI API to interact with GPT-based large language models (LLMs).

## Configuration

```
class ExampleDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration {
            OpenAIComponent()
            // ...
        }
    }
}
```

You can provide a default API token or model configuration to the OpenAI component's ``OpenAIComponent/init(apiToken:openAIModel:)`` initializer in the configuration.
The choice of model and the API key are persisted across application launches.


## Usage

The ``OpenAIComponent`` can subsequentially be used in a SwiftUI View using the environment dependency injection mechanism.

```
struct ExampleOpenAIView: View {
    @EnvironmentObject var openAI: OpenAIComponent</* ... */>

    // ...
}
```

The ``OpenAIComponent``'s ``OpenAIComponent/apiToken`` and ``OpenAIComponent/openAIModel`` can be accessed and changed at runtime.
The ``OpenAIComponent/queryAPI(withChat:)`` function allows the interaction with the GPT-based OpenAI models.


## Types

### Open AI GPT

- ``OpenAIGPT``
- ``OpenAIGPTError``
