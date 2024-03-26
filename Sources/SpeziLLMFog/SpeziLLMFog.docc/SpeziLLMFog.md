# ``SpeziLLMFog``

<!--
#
# This source file is part of the Stanford Spezi open source project
#
# SPDX-FileCopyrightText: 2023 Stanford University and the project authors (see CONTRIBUTORS.md)
#
# SPDX-License-Identifier: MIT
#       
-->

Discover and dispatch Large Language Models (LLMs) inference jobs to Fog node resources within the local network.

## Overview

A module that allows you to interact with Fog node-based Large Language Models (LLMs) in the local network within your Spezi application.
``SpeziLLMFog`` automatically discovers LLM computing resources within the local network, establishes a connection to these [Fog nodes](https://en.wikipedia.org/wiki/Fog_computing), and then dispatches LLM inference jobs to these nodes. The response is then streamed back to ``SpeziLLMFog`` and surfaced to the user. The fog nodes advertise their services via [mDNS](https://en.wikipedia.org/wiki/Multicast_DNS), enabling clients to discover all fog nodes serving a specific host within the local network.
``SpeziLLMFog`` provides a pure Swift-based API for interacting with the Fog LLMs, building on top of the infrastructure of the [SpeziLLM target](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm).

## Setup

### Add Spezi LLM as a Dependency

You need to add the SpeziLLM Swift package to
[your app in Xcode](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app#) or
[Swift package](https://developer.apple.com/documentation/xcode/creating-a-standalone-swift-package-with-xcode#Add-a-dependency-on-another-Swift-package).

> Important: If your application is not yet configured to use Spezi, follow the [Spezi setup article](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/initial-setup) to set up the core Spezi infrastructure.

## Spezi LLM Fog Components

The core components of the ``SpeziLLMFog`` target are the ``LLMFogSchema``, ``LLMFogSession`` as well as ``LLMFogPlatform``. These components enable users to automatically discover Fog LLM resources via [mDNS](https://en.wikipedia.org/wiki/Multicast_DNS) and dispatch jobs to these nodes which are then performing the LLM inference on open-source LLMs like Llama2 or Gemma.

> Important: ``SpeziLLMFog`` requires a `SpeziLLMFogNode` within the local network hosted on some computing resource that actually performs the inference requests. ``SpeziLLMFog`` provides the `SpeziLLMFogNode` Docker-based package that enables an out-of-the-box setup of these fog nodes. See the `FogNode` directory on the root level of the SPM package as well as the respective `README.md` for more details.

> Tip: In order to utilize Fog LLMs, the user must be authenticated via the [`SpeziFirebaseAccount`](https://github.com/StanfordSpezi/SpeziFirebase) identify provider of [`SpeziAccount`](https://github.com/StanfordSpezi/SpeziAccount). The fog node then validates the identify of the client by checking the Firebase ID token that is automatically sent with every Fog LLM inference request.

### LLM Fog

``LLMFogSchema`` offers a variety of configuration possibilities that are supported by the Fog LLM APIs (mirroring the OpenAI API implementation), such as the model type, the system prompt, the temperature of the model, and many more. These options can be set via the ``LLMFogSchema/init(parameters:modelParameters:injectIntoContext:)`` initializer and the ``LLMFogParameters`` and ``LLMFogModelParameters``.

This ``LLMFogSchema`` is then turned into an in-execution ``LLMFogSession`` by the `LLMRunner` via the ``LLMFogPlatform``. The ``LLMFogSession`` is the executable version of a Fog LLM containing context and state as defined by the ``LLMFogSchema``.
As the to-be-used models are running on a Fog node within the local network, the respective LLM computing resource (so the fog node) is discovered upon setup of the ``LLMFogSession``, meaning a ``LLMFogSession`` is bound to a specific fog node after initialization.

- Important: The Fog LLM abstractions shouldn't be used on it's own but always used together with the Spezi `LLMRunner`.

#### Setup

In order to use Fog LLMs within the Spezi ecosystem, the [SpeziLLM](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm) [`LLMRunner`](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm/llmrunner) needs to be initialized in the Spezi `Configuration` with the `LLMFogPlatform`. Only after, the `LLMRunner` can be used for inference with Fog LLMs. See the [SpeziLLM documentation](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm) for more details.
The `LLMFogPlatform` needs to be initialized with the custom root CA certificate that was used to sign the fog node web service certificate (see the `FogNode/README.md` documentation for more information). Copy the root CA certificate from the fog node as resource to the application using `SpeziLLMFog` and use it to initialize the `LLMFogPlatform` within the Spezi `Configuration`.

As the `LLMFogPlatform` uses Firebase to verify the identify of users and determine their authorization to use fog LLM resources, one must setup [`SpeziAccount`](https://github.com/StanfordSpezi/SpeziAccount) as well as [`SpeziFirebaseAccount`](https://github.com/StanfordSpezi/SpeziFirebase) in the Spezi `Configuration`.
Specifically, one must state the `AccountConfiguration` as well as the `FirebaseAccountConfiguration` in the `Configuration`, otherwise a crash upon startup of Spezi will occur. Resulting from that, the application must contain the [`GoogleService-Info.plist` file issued by Firebase](https://firebase.google.com/docs/ios/setup) so that the `FirebaseAccountConfiguration` is able to use the correct Firebase project.

```swift
class LLMFogAppDelegate: SpeziAppDelegate {
    private nonisolated static var caCertificateUrl: URL {
        // Return local file URL of root CA certificate in the `.crt` format
    }

    override var configuration: Configuration {
        Configuration {
            // Sets up SpeziAccount and the required account details
            AccountConfiguration(configuration: [
                .requires(\.userId),
                .requires(\.password)
            ])

            // Sets up SpeziFirebaseAccount which serves as the identity provider for the SpeziAccount setup above
            FirebaseAccountConfiguration(authenticationMethods: .emailAndPassword)

            LLMRunner {
                LLMFogPlatform(configuration: .init(caCertificate: Self.caCertificateUrl))
            }
        }
    }
}
```

- Important: For development purposes, one is able to configure the fog node in the development mode, meaning no TLS connection (resulting in no need for custom certificates) as well as the usage of the Firebase emulator (not the real Firebase cloud instance). See the `FogNode/README.md` for more details regarding server-side (so fog node) instructions.
On the client-side within Spezi, one has to pass `nil` for the `caCertificate` parameter of the ``LLMFogPlatform`` as shown above. In addition, one has to specify the usage of the Firebase emulator via the `host` and `port` parameters in the `FirebaseAccountConfiguration`, like: `FirebaseAccountConfiguration(authenticationMethods: .emailAndPassword, emulatorSettings: (host: "localhost", port: 9099))`.
If used in development mode, no custom CA certificate or Firebase `GoogleService-Info.plist` file is required, ensuring a smooth and straightforward development process.

#### Usage

The code example below showcases the interaction with a Fog LLM through the the [SpeziLLM](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm) [`LLMRunner`](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm/llmrunner), which is injected into the SwiftUI `Environment` via the `Configuration` shown above.

The ``LLMFogSchema`` defines the type and configurations of the to-be-executed ``LLMFogSession``. This transformation is done via the [`LLMRunner`](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm/llmrunner) that uses the ``LLMFogPlatform``. The inference via ``LLMFogSession/generate()`` returns an `AsyncThrowingStream` that yields all generated `String` pieces.
The ``LLMFogSession`` automatically discovers all available LLM fog nodes within the local network upon setup and the dispatches the LLM inference jobs to the fog computing resource, streaming back the response and surfaces it to the user.

The ``LLMFogSession`` contains the ``LLMFogSession/context`` property which holds the entire history of the model interactions. This includes the system prompt, user input, but also assistant responses.
Ensure the property always contains all necessary information, as the ``LLMFogSession/generate()`` function executes the inference based on the ``LLMFogSession/context``.

```swift
struct LLMFogDemoView: View {
    @Environment(LLMRunner.self) var runner
    @State var responseText = ""

    var body: some View {
        Text(responseText)
            .task {
                // Instantiate the `LLMFogSchema` to an `LLMFogSession` via the `LLMRunner`.
                let llmSession: LLMFogSession = runner(
                    with: LLMFogSchema(
                        parameters: .init(
                            modelType: .llama7B,
                            systemPrompt: "You're a helpful assistant that answers questions from users."
                        )
                    )
                )

                for try await token in try await llmSession.generate() {
                    responseText.append(token)
                }
            }
    }
}
```

## Topics

### LLM Fog abstraction

- ``LLMFogSchema``
- ``LLMFogSession``

### LLM Execution

- ``LLMFogPlatform``
- ``LLMFogPlatformConfiguration``

### LLM Configuration

- ``LLMFogParameters``
- ``LLMFogModelParameters``

### Misc

- ``LLMFogError``
