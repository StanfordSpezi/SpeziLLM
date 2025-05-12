//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Network


extension LLMFogPlatform {
    // todo: check if we actually want something like that!
    /// Browse for mDNS services and return the final set observed after `mDnsBrowsingTimeout` elapses.
    static func discoverFogServices(
        configuration: LLMFogPlatformConfiguration
    ) async throws -> Set<NWBrowser.Result> {
        let sequence = ServiceDiscoverySequence(serviceType: configuration.connectionType.mDnsServiceType, host: configuration.host)
        var lastResults = Set<NWBrowser.Result>()

        // Task that keeps updating lastResults as new snapshots arrive
        let collector = Task { () -> Set<NWBrowser.Result> in
            for try await snapshot in sequence {
                lastResults = snapshot
            }
            return lastResults
        }

        // Let browsing run for the configured timeout
        try await Task.sleep(for: configuration.mDnsBrowsingTimeout)
        collector.cancel()

        return try await collector.value
    }

    
    static func resolveFogEndpoint(_ endpoint: NWEndpoint) async throws -> String {
        let connection = NWConnection(to: endpoint, using: .tcp)
        connection.start(queue: .global(qos: .userInitiated))
        defer { connection.cancel() }

        // Wait until .ready, .failed or .cancelled
        try await withCheckedThrowingContinuation { continuation in
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    // Stop observing further state changes
                    connection.stateUpdateHandler = nil
                    continuation.resume()
                case .failed(let error):
                    connection.stateUpdateHandler = nil
                    continuation.resume(throwing: LLMFogError.mDnsServiceDiscoveryNetworkError(error))
                case .cancelled:
                    connection.stateUpdateHandler = nil
                    continuation.resume(throwing: CancellationError())
                default:
                    break
                }
            }
        }

        // After ready, extract the host portion of the endpoint
        guard
            let path = connection.currentPath,
            case let .hostPort(host, _) = path.remoteEndpoint,
            let rawAddress = host.debugDescription          // todo: check if this split works, but we need to refine that either way..
                .split(separator: "%", maxSplits: 1, omittingEmptySubsequences: true)
                .first
        else {
            Self.logger.error(
                "SpeziLLMFog: Failed to resolve endpoint \(endpoint.debugDescription)"
            )
            throw LLMFogError.mDnsServicesNotFound
        }

        let ipAddress = String(rawAddress)
        Self.logger.debug(
            "SpeziLLMFog: Resolved \(endpoint.debugDescription) → \(ipAddress)"
        )
        return ipAddress
    }
}
