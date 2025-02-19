<!--
                  
This source file is part of the Stanford Spezi open source project

SPDX-FileCopyrightText: 2023 Stanford University and the project authors (see CONTRIBUTORS.md)

SPDX-License-Identifier: MIT
             
-->

# Generated OpenAI client

This SPM target uses the [`swift-openapi-generator`](https://github.com/apple/swift-openapi-generator) to generate Swift client code from the [OpenAI OpenAPI specification](https://github.com/openai/openai-openapi) and provides the generated code to other SpeziLLM targets. The generator's configuration is defined in `openapi-generator-config.yaml`, while the specification is located in `openapi.yaml`.

### Why Preprocessing is Needed

The OpenAI OpenAPI specification contains the following issues that require preprocessing before code generation:

- **Incorrect `required` Property**: A non-existent property is incorrectly marked as `required` (see [`openai-openapi#421`](https://github.com/openai/openai-openapi/issues/421)).
- **Unsupported `oneOf` Syntax**: The `swift-openapi-generator` does not fully support `oneOf` with `required` properties (see [`swift-openapi-generator#739`](https://github.com/apple/swift-openapi-generator/issues/739)).
- **Deprecation Warnings**: `deprecated` markings in the OpenAPI spec trigger warnings in the generated Swift code (see [`swift-openapi-generator#106`](https://github.com/apple/swift-openapi-generator/issues/106) and [`swift-openapi-generator#715`](https://github.com/apple/swift-openapi-generator/issues/715)).

Without preprocessing, these issues result in unnecessary warnings during the Swift code generation and in the resulting Swift client code.

### Running the Preprocessing Script

After updating the used [OpenAI OpenAPI specification](https://github.com/openai/openai-openapi) in SpeziLLM, run the preprocessing script to prepare the spec for use in SpeziLLM.

#### **Steps:**
1. Navigate to the generated client directory:

```sh
cd Sources/GeneratedOpenAIClient
```

2. Ensure the script is executable:

```sh
chmod +x preprocess-openapi-spec.sh
```


3. Run the preprocessing script:

```sh
./preprocess-openapi-spec.sh
```


After running the script, the specification will be correctly formatted and ready for Swift client code generation.
