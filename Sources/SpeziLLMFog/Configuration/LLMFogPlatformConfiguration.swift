//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import GeneratedOpenAIClient


/// Represents the configuration of the Spezi ``LLMFogPlatform``.
public struct LLMFogPlatformConfiguration: Sendable {
    /// Name of the to-be-discovered service within the local network.
    let host: String
    /// Root CA certificate which should be trusted for the TLS network connection.
    let caCertificate: URL?
    /// Closure that returns an up-to-date auth token for requests to Fog LLMs (e.g., a Firebase ID token).
    let authToken: RemoteLLMInferenceAuthToken
    /// Task priority of the initiated LLM inference tasks.
    let taskPriority: TaskPriority
    /// Number of concurrent streams to the Fog LLM.
    let concurrentStreams: Int
    /// Maximum network timeout of Fog LLM requests in seconds.
    let timeout: TimeInterval
    /// Duration of mDNS browsing for Fog LLM services.
    let mDnsBrowsingTimeout: Duration
    
    
    /// Creates the ``LLMFogPlatformConfiguration`` which configures the Spezi ``LLMFogPlatform``.
    ///
    /// - Parameters:
    ///   - host: The name of the to-be-discovered service within the local network via mDNS. The hostname must match the issued TLS certificate of the fog node. Defaults to `spezillmfog.local` which is used for the mDNS advertisements as well as the TLS certificate.
    ///   - caCertificate: The root CA certificate which should be trusted for the TLS network connection. The host certificate must be signed via the CA certificate.
    ///   - authToken: Closure that returns an up-to-date auth token for requests to Fog LLMs (e.g., a Firebase ID token).
    ///   - taskPriority: The task priority of the initiated LLM inference tasks, defaults to `.userInitiated`.
    ///   - concurrentStreams: Indicates the number of concurrent streams to the Fog LLM, defaults to `5`.
    ///   - timeout: Indicates the maximum network timeout of Fog LLM requests in seconds. defaults to `60`.
    ///   - mDnsBrowsingTimeout: Duration of mDNS browsing for Fog LLM services, default to `100ms`.
    public init(
        host: String = "spezillmfog.local",
        caCertificate: URL? = nil,
        authToken: RemoteLLMInferenceAuthToken,
        taskPriority: TaskPriority = .userInitiated,
        concurrentStreams: Int = 5,
        timeout: TimeInterval = 60,
        mDnsBrowsingTimeout: Duration = .milliseconds(100)
    ) {
        self.host = host
        self.caCertificate = caCertificate
        self.authToken = authToken
        self.taskPriority = taskPriority
        self.concurrentStreams = concurrentStreams
        self.timeout = timeout
        self.mDnsBrowsingTimeout = mDnsBrowsingTimeout
    }
}
