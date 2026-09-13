<!--
                  
This source file is part of the Stanford Spezi open source project

SPDX-FileCopyrightText: 2023 Stanford University and the project authors (see CONTRIBUTORS.md)

SPDX-License-Identifier: MIT
             
-->

# Generated OpenAI client

This SPM target uses the [`swift-openapi-generator`](https://github.com/apple/swift-openapi-generator) to generate Swift client code from the [OpenAI OpenAPI specification](https://github.com/openai/openai-openapi) and provides the generated code to other SpeziLLM targets. The generator's configuration is defined in `openapi-generator-config.yaml`, while the specification is located in `openapi.yaml`.

The specification corresponds to upstream commit [`38170fd`](https://github.com/openai/openai-openapi/commit/38170fdddbb6a1813eae6c6587ee17cf2987185b) from 2026-09-11, after preprocessing.

### What gets generated

Only the operations and schemas that SpeziLLM uses are generated. The `filter` section of `openapi-generator-config.yaml` lists them, and everything they reference is included transitively. Generating the whole document would add tens of thousands of lines of unused Swift to every build of the package. Before using another operation or schema from a SpeziLLM target, add it to the filter.

### Why preprocessing is needed

The upstream document is written for OpenAI's documentation tooling rather than for code generators. `preprocess-openapi-spec.js` applies a set of general rules to the whole document, each documented in the script, so that a newer upstream revision needs no changes to the script:

- Deprecated operations, schemas, and properties are removed, so the generated code carries no deprecation warnings.
- The `webhooks` section is removed. The generator produces nothing for it, and its references would dangle once the document is filtered.
- `$recursiveRef` is rewritten into a plain self reference, which the generator understands.
- OpenAPI 3.0 boolean `exclusiveMinimum`/`exclusiveMaximum` are converted to the 3.1 numeric form.
- Every spelling of a nullable schema (`nullable: true`, `type: [T, "null"]`, and `anyOf`/`oneOf` with a `null` branch) collapses to the non-null schema, and nullable properties are removed from `required`, so they become Swift optionals rather than wrapper types.
- `required` only keeps names that exist on the same object. The document lists properties as required that live on a sibling `allOf` member or do not exist at all.
- Composition constraints that only express which keys must be present are removed, and array constraints misplaced on element schemas are moved to the array.
- Discriminated unions without a `mapping` get one derived from each branch's discriminator value. Without it, the generator matches on the schema name, and OpenAI's `type` values (`function`, `url_citation`, …) differ from the schema names (`FunctionTool`, `UrlCitationBody`, …), so decoding fails on data the API really sends.

### Updating the specification

#### Prerequisites

Make sure Node.js and npm are installed on your system, either via `brew install node` on macOS or `sudo apt install nodejs npm` on Ubuntu / Linux.

#### Steps

1. Navigate to the generated client directory and install the dependencies (if not already installed):

```sh
cd Sources/GeneratedOpenAIClient
npm install
```

2. Fetch the latest upstream document and preprocess it:

```sh
npm run update
```

To preprocess a document that is already on disk, run `npm run preprocess` instead.

3. Build the package. The generator runs as a build plugin, and compile errors in the consuming targets show where generated types changed shape. The decoding tests in `SpeziLLMTests` check the generated types against OpenAI's own example payloads.

4. Update the upstream commit noted at the top of this file.
