//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Spezi
import SpeziFoundation
import SpeziLLM


/// LLM execution platform of an ``LLMFogSchema``.
///
/// The ``LLMFogPlatform`` turns a received ``LLMFogSchema`` to an executable ``LLMFogSession`` which runs on an LLM Fog node within the local network.
/// Use ``LLMFogPlatform/callAsFunction(with:)`` with an ``LLMFogSchema`` parameter to get an executable ``LLMFogSession`` that does the actual inference.
/// 
/// It is important to note that the ``LLMFogPlatform`` discovers fog computing resources within the local network and then dispatches LLM inference jobs to these fog nodes.
/// In turn, that means that such a fog node must exist within the local network, see the `FogNode` distributed with the package.
///
/// In order to establish a secure connection to the fog node, the TLS encryption mechanism is used.
/// That results in the need for the ``LLMFogPlatform`` to be configured via ``LLMFogPlatform/init(configuration:)`` and
/// ``LLMFogPlatformConfiguration/init(host:caCertificate:taskPriority:concurrentStreams:timeout:mDnsBrowsingTimeout:)`` with the custom
/// root CA certificate in the `.crt` format that signed the web service certificate of the fog node. See the `FogNode/README.md` and specifically the `setup.sh` script for more details.
///
/// - Important: ``LLMFogPlatform`` shouldn't be used directly but used via the `SpeziLLM` `LLMRunner` that delegates the requests towards the ``LLMFogPlatform``.
/// The `SpeziLLM` `LLMRunner` must be configured with the ``LLMFogPlatform`` within the Spezi `Configuration`.
///
/// - Tip: For more information, refer to the documentation of the `LLMPlatform` from SpeziLLM.
///
/// ### Usage
///
/// The example below demonstrates the setup of the ``LLMFogPlatform`` within the Spezi `Configuration`. The initializer requires the passing of a local `URL` to the root CA certificate in the `.crt` format that signed the web service certificate on the fog node. See the `FogNode/README.md` and specifically the `setup.sh` script for more details.
///
/// ```swift
/// class TestAppDelegate: SpeziAppDelegate {
///     private nonisolated static var caCertificateUrl: URL {
///         // Return local file URL of root CA certificate in the `.crt` format
///     }
///
///     override var configuration: Configuration {
///         Configuration {
///             LLMRunner {
///                 LLMFogPlatform(configuration: .init(caCertificate: Self.caCertificateUrl))
///             }
///         }
///     }
/// }
/// ```
///
/// - Important: For development purposes, one is able to configure the fog node in the development mode, meaning no TLS connection (resulting in no need for custom certificates). See the `FogNode/README.md` for more details regarding server-side (so fog node) instructions.
/// On the client-side within Spezi, one has to pass `nil` for the `caCertificate` parameter of the ``LLMFogPlatform`` as shown above. If used in development mode, no custom CA certificate is required, ensuring a smooth and straightforward development process.
public actor LLMFogPlatform: LLMPlatform {
    /// Enforce an arbitrary number of concurrent execution jobs of Fog LLMs.
    private let semaphore: AsyncSemaphore
    let configuration: LLMFogPlatformConfiguration
    
    @MainActor public var state: LLMPlatformState = .idle
    
    
    /// Creates an instance of the ``LLMFogPlatform``.
    ///
    /// - Parameters:
    ///     - configuration: The configuration of the platform.
    public init(configuration: LLMFogPlatformConfiguration) {
        self.configuration = configuration
        self.semaphore = AsyncSemaphore(value: configuration.concurrentStreams)
    }
    
    
    public nonisolated func callAsFunction(with llmSchema: LLMFogSchema) -> LLMFogSession {
        LLMFogSession(self, schema: llmSchema)
    }
    
    func exclusiveAccess() async throws {
        try await semaphore.waitCheckingCancellation()
        
        if await state != .processing {
            await MainActor.run {
                state = .processing
            }
        }
    }
    
    func signal() async {
        let otherTasksWaiting = semaphore.signal()
        
        if !otherTasksWaiting {
            await MainActor.run {
                state = .idle
            }
        }
    }
    
    
    deinit {
    }
}
