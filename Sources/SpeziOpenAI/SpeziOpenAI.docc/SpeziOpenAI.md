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
        Configuration(standard: /* ... */) {
            OpenAIComponent()
            // ...
        }
    }
}
```

You can provide a default API token or model configuration to the OpenAPI component in the configuration.
The choice of model and the API key are persisted across application launches.


## Usage



## Types

### Open AI GPT

- ``OpenAIGPT``
- ``OpenAIGPTError``
