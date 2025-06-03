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

> Important: ``SpeziLLMFog`` performs dynamic discovery of available fog node services in the local network using Bonjour. To enable this functionality, the consuming application must configure the following `Info.plist` entries:
> - `NSLocalNetworkUsageDescription` (`String`): A description explaining why the app requires access to the local network. For example:
`"This app uses local network access to discover nearby services."`
> - `NSBonjourServices` (`Array<String>`): Specifies the Bonjour service types the app is allowed to discover.
> For use with ``SpeziLLMFog``, include the following entry:
>   - `_https._tcp` (for discovering secured services via TLS)
>   - `_http._tcp` (optional, for testing purposes only; discovers unsecured services)

### LLM Fog

``LLMFogSchema`` offers a variety of configuration possibilities that are supported by the Fog LLM APIs (mirroring the OpenAI API implementation), such as the model type, the system prompt, the temperature of the model, and many more. These options can be set via the ``LLMFogSchema/init(parameters:modelParameters:injectIntoContext:)`` initializer and the ``LLMFogParameters`` and ``LLMFogModelParameters``.

This ``LLMFogSchema`` is then turned into an in-execution ``LLMFogSession`` by the `LLMRunner` via the ``LLMFogPlatform``. The ``LLMFogSession`` is the executable version of a Fog LLM containing context and state as defined by the ``LLMFogSchema``.
As the to-be-used models are running on a Fog node within the local network, the respective LLM computing resource (so the fog node) is discovered upon setup of the ``LLMFogSession``, meaning a ``LLMFogSession`` is bound to a specific fog node after initialization.

- Important: The Fog LLM abstractions shouldn't be used on it's own but always used together with the Spezi `LLMRunner`.

#### Setup

In order to use Fog LLMs within the Spezi ecosystem, the [SpeziLLM](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm) [`LLMRunner`](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm/llmrunner) needs to be initialized in the Spezi `Configuration` with the `LLMFogPlatform`. Only after, the `LLMRunner` can be used for inference with Fog LLMs. See the [SpeziLLM documentation](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm) for more details.
The `LLMFogPlatform` needs to be initialized with the custom root CA certificate that was used to sign the fog node web service certificate (see the `FogNode/README.md` documentation for more information). Copy the root CA certificate from the fog node as resource to the application using `SpeziLLMFog` and use it to initialize the `LLMFogPlatform` within the Spezi `Configuration`.

```swift
class LLMFogAppDelegate: SpeziAppDelegate {
    private nonisolated static var caCertificateUrl: URL {
        // Return local file URL of root CA certificate in the `.crt` format
    }

    override var configuration: Configuration {
        Configuration {
            LLMRunner {
                LLMFogPlatform(configuration: .init(caCertificate: Self.caCertificateUrl))
            }
        }
    }
}
```

- Important: For development purposes, one is able to configure the fog node in the development mode, meaning no TLS connection (resulting in no need for custom certificates). See the `FogNode/README.md` for more details regarding server-side (so fog node) instructions.
On the client-side within Spezi, one has to pass `nil` for the `caCertificate` parameter of the ``LLMFogPlatform`` as shown above. If used in development mode, no custom CA certificate is required, ensuring a smooth and straightforward development process.

In addition to set local network discovery entitlements described above, users must grant explicit authorization for local network access.
This authorization can be requested during the app’s onboarding process using ``LLMFogDiscoveryAuthorizationView``.
It informs users about the need for local network access, prompts them to grant it, and attempts to verify the access status (note: the OS does not expose this information).
For detailed guidance on integrating the ``LLMFogDiscoveryAuthorizationView`` in an onboarding flow managed by `[SpeziOnboarding`](https://swiftpackageindex.com/stanfordspezi/spezionboarding), refer to the in-line documentation of the ``LLMFogDiscoveryAuthorizationView``.

#### Usage

The code example below showcases the interaction with a Fog LLM through the the [SpeziLLM](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm) [`LLMRunner`](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm/llmrunner), which is injected into the SwiftUI `Environment` via the `Configuration` shown above.

The ``LLMFogSchema`` defines the type and configurations of the to-be-executed ``LLMFogSession``. This transformation is done via the [`LLMRunner`](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm/llmrunner) that uses the ``LLMFogPlatform``. The inference via ``LLMFogSession/generate()`` returns an `AsyncThrowingStream` that yields all generated `String` pieces.
The ``LLMFogSession`` automatically discovers all available LLM fog nodes within the local network upon setup and the dispatches the LLM inference jobs to the fog computing resource, streaming back the response and surfaces it to the user.

- Note: Use the ``LLMFogDiscoverySelectionView`` to give users more freedom about the discovered and selected fog resource within the local network.

The ``LLMFogSession`` contains the ``LLMFogSession/context`` property which holds the entire history of the model interactions. This includes the system prompt, user input, but also assistant responses.
Ensure the property always contains all necessary information, as the ``LLMFogSession/generate()`` function executes the inference based on the ``LLMFogSession/context``.

- Important: The ``LLMFogSchema`` accepts a closure that returns an authorization token that is passed with every request to the Fog node in the `Bearer` HTTP field via the ``LLMFogParameters/init(modelType:overwritingAuthToken:systemPrompt:)``. The token is created via the closure upon every LLM inference request, as the ``LLMFogSession`` may be long lasting and the token could therefore expire. Ensure that the closure appropriately caches the token in order to prevent unnecessary token refresh roundtrips to external systems.

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
                            systemPrompt: "You're a helpful assistant that answers questions from users.",
                            authToken: { 
                                // Return authorization token as `String` or `nil` if no token is required by the Fog node.
                            }
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

### Fog node discovery and auth

- ``LLMFogDiscoverySelectionView``
- ``LLMFogDiscoveryAuthorizationView``
- ``LLMFogAuthTokenOnboardingStep``

### Misc

- ``LLMFogError``
