//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Spezi
import SpeziFirebaseAccount
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
/// ``LLMFogPlatformConfiguration/init(caCertificate:host:taskPriority:concurrentStreams:timeout:mDnsBrowsingTimeout:)`` with the custom
/// root CA certificate in the `.crt` format that signed the web service certificate of the fog node. See the `FogNode/README.md` and specifically the `setup.sh` script for more details.
///
/// - Important: ``LLMFogPlatform`` shouldn't be used directly but used via the `SpeziLLM` `LLMRunner` that delegates the requests towards the ``LLMFogPlatform``.
/// The `SpeziLLM` `LLMRunner` must be configured with the ``LLMFogPlatform`` within the Spezi `Configuration`.
///
/// - Tip: For more information, refer to the documentation of the `LLMPlatform` from SpeziLLM.
///
/// - Important: As the ``LLMFogPlatform`` uses Firebase to verify the identify of users and determine their authorization to use fog LLM resources, one must setup [`SpeziAccount`](https://github.com/StanfordSpezi/SpeziAccount)
///   as well as [`SpeziFirebaseAccount`](https://github.com/StanfordSpezi/SpeziFirebase) in the Spezi `Configuration`.
///   Specifically, one must state the `AccountConfiguration` as well as the `FirebaseAccountConfiguration` in the `Configuration`, otherwise a crash upon startup of Spezi will occur.
///
/// ### Usage
///
/// The example below demonstrates the setup of the ``LLMFogPlatform`` within the Spezi `Configuration`. The initializer requires the passing of a local `URL` to the root CA certificate in the `.crt` format that signed the web service certificate on the fog node. See the `FogNode/README.md` and specifically the `setup.sh` script for more details.
/// It is important to note that the `AccountConfiguration` as well as the `FirebaseAccountConfiguration` have to be stated as well in order to use the ``LLMFogPlatform``.
///
/// ```swift
/// class TestAppDelegate: SpeziAppDelegate {
///     private nonisolated static var caCertificateUrl: URL {
///         // Return local file URL of root CA certificate in the `.crt` format
///     }
///
///     override var configuration: Configuration {
///         Configuration {
///             // Sets up SpeziAccount and the required account details
///             AccountConfiguration(configuration: [
///                 .requires(\.userId),
///                 .requires(\.password)
///             ])
///
///             // Sets up SpeziFirebaseAccount which serves as the identity provider for the SpeziAccount setup above
///             FirebaseAccountConfiguration(authenticationMethods: .emailAndPassword)
///
///             LLMRunner {
///                 LLMFogPlatform(configuration: .init(caCertificate: Self.caCertificateUrl))
///             }
///         }
///     }
/// }
/// ```
public actor LLMFogPlatform: LLMPlatform {
    /// Enforce an arbitrary number of concurrent execution jobs of Fog LLMs.
    private let semaphore: AsyncSemaphore
    let configuration: LLMFogPlatformConfiguration
    
    @MainActor public var state: LLMPlatformState = .idle
    /// Dependency to the FirebaseAccountConfiguration, ensuring that it is present in the Spezi `Configuration`.
    @Dependency private var firebaseAuth: FirebaseAccountConfiguration?
    
    
    /// Creates an instance of the ``LLMFogPlatform``.
    ///
    /// - Parameters:
    ///     - configuration: The configuration of the platform.
    public init(configuration: LLMFogPlatformConfiguration) {
        self.configuration = configuration
        self.semaphore = AsyncSemaphore(value: configuration.concurrentStreams)
    }
    
    
    public nonisolated func configure() {
        Task {
            guard await firebaseAuth != nil else {
                preconditionFailure("""
                SpeziLLMFog: Ensure that the `AccountConfiguration` and `FirebaseAccountConfiguration` are stated within the Spezi `Configuration`
                to set up the required Firebase account authentication of the `LLMFogPlatform`.
                """)
            }
        }
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
