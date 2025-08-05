//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import GeneratedOpenAIClient
import Network
import OpenAPIRuntime
import OpenAPIURLSession
import SpeziKeychainStorage
import SpeziLLM


extension LLMFogSession {
    /// Set up the Fog LLM execution client.
    ///
    /// - Parameters:
    ///   - continuationObserver: A `ContinuationObserver` that tracks a Swift `AsyncThrowingStream` continuation for cancellation.
    /// - Returns: `true` if the setup was successful, `false` otherwise.
    func _setup(with continuationObserver: ContinuationObserver<String, any Error>) async -> Bool {
        // swiftlint:disable:previous function_body_length identifier_name
        Self.logger.debug("SpeziLLMFog: Fog LLM is being initialized")
        await MainActor.run {
            self.state = .loading
        }
        
        var caCertificate: SecCertificate?
        
        if case let .https(caCertificateUrl) = self.platform.configuration.connectionType {
            // Load the specified CA certificate and strip out irrelevant data
            guard let caCertificateContents = try? String(contentsOf: caCertificateUrl, encoding: .utf8)
                    .replacingOccurrences(of: "-----BEGIN CERTIFICATE-----", with: "")
                    .replacingOccurrences(of: "-----END CERTIFICATE-----", with: "")
                    .replacingOccurrences(of: "\n", with: ""),
                  let caCertificateData = Data(base64Encoded: caCertificateContents),
                  let caCreatedCertificate = SecCertificateCreateWithData(nil, caCertificateData as CFData) else {
                Self.logger.error("""
                SpeziLLMFog: The to-be-trusted CA certificate ensuring encrypted traffic to the fog LLM couldn't be read.
                Please ensure that the certificate is in the `.crt` format and available under the specified URL.
                """)
                await finishGenerationWithError(LLMFogError.missingCaCertificate, on: continuationObserver.continuation)
                return false
            }
            
            caCertificate = caCreatedCertificate
        }

        if continuationObserver.isCancelled {
            Self.logger.warning("SpeziLLMFog: Generation cancelled by the user.")
            await MainActor.run {
                self.state = .uninitialized
            }
            return false
        }

        let fogServiceAddress: String
        
        do {
            // If preferred fog service already discovered, just resolve it to a concrete address
            if let preferredFogService = await self.platform.preferredFogService {
                fogServiceAddress = try await Self.resolveFogService(discoveredEndpoint: preferredFogService)
            } else {
                // Otherwise, discover and resolve fog service
                let fogServiceEndpoint = try await Self.discoverFogService(configuration: self.platform.configuration)
                fogServiceAddress = try await Self.resolveFogService(discoveredEndpoint: fogServiceEndpoint)
            }

            await MainActor.run {
                self.discoveredServiceAddress = fogServiceAddress
            }
        } catch let error as LLMFogError {
            await finishGenerationWithError(error, on: continuationObserver.continuation)
            return false
        } catch {
            await finishGenerationWithError(LLMFogError.unknownError(error.localizedDescription), on: continuationObserver.continuation)
            return false
        }

        if continuationObserver.isCancelled {
            Self.logger.warning("SpeziLLMFog: Generation cancelled by the user.")
            await MainActor.run {
                self.state = .uninitialized
            }
            return false
        }

        // Initialize the OpenAI client
        let host: String
        // If IPv6 address, surround the address with '[' and ']' as required by RFC 3986: https://datatracker.ietf.org/doc/html/rfc3986
        if fogServiceAddress.contains(":") && !fogServiceAddress.hasPrefix("[") && !fogServiceAddress.hasSuffix("]") {
            host = "[\(fogServiceAddress)]"
        } else {
            host = fogServiceAddress
        }

        // URL in format: `http(s)://<DISCOVERED_SERVICE_ADDRESS>:<PORT>/v1`
        let urlString = """
        \((caCertificate != nil) ? "https" : "http")://\(host):\((caCertificate != nil) ? 443 : 80)/v1
        """
        guard let url = URL(string: urlString) else {
            await finishGenerationWithError(LLMFogError.mDnsServicesNotFound, on: continuationObserver.continuation)
            return false
        }

        let bearerAuthMiddleware = BearerAuthMiddleware(
            authToken: {
                if let overwritingToken = self.schema.parameters.overwritingAuthToken {
                    return overwritingToken
                }

                return self.platform.configuration.authToken
            }(),
            keychainStorage: self.keychainStorage
        )

        self.fogNodeClient = Client(
            serverURL: url,
            transport: {
                let session = URLSession(
                    configuration: .default,
                    delegate: TransportCertificateValidationDelegate(
                        caCertificate: caCertificate,
                        expectedHost: platform.configuration.host,
                        logger: Self.logger
                    ),
                    delegateQueue: nil
                )
                session.configuration.timeoutIntervalForRequest = platform.configuration.timeout

                return URLSessionTransport(
                    configuration: .init(
                        session: session
                    )
                )
            }(),
            middlewares: [
                // Injects the bearer auth token for account verification into request headers
                bearerAuthMiddleware,
                // Injects the expected custom hostname into request headers
                ExpectedHostMiddleware(expectedHost: platform.configuration.host),
                // Retry policy for failed requests
                RetryMiddleware(policy: self.platform.configuration.retryPolicy)
            ]
        )

        await MainActor.run {
            self.state = .ready
        }
        Self.logger.debug("SpeziLLMFog: Fog LLM finished initializing, now ready to use")
        return true
    }
}

extension LLMFogSession {
    /// Discovers available fog services in the local network.
    fileprivate static func discoverFogService(
        configuration: LLMFogPlatformConfiguration
    ) async throws -> NWBrowser.Result {
        // Otherwise, browse for configured mDNS services and discover endpoints
        let browser = NWBrowser(
            for: .bonjour(
                type: configuration.connectionType.mDnsServiceType,
                domain: configuration.host + "."
            ),
            using: .init()
        )

        browser.start(queue: .global(qos: .userInitiated))

        // Possible `Cancellation` error handled in the caller
        try await Task.sleep(for: configuration.mDnsBrowsingTimeout)

        guard let discoveredEndpoint = browser.browseResults.randomElement() else {
            browser.cancel()
            Self.logger.error("SpeziLLMFog: A \(configuration.host + ".") mDNS service of type '\(configuration.connectionType.mDnsServiceType)' could not be found.")
            throw LLMFogError.mDnsServicesNotFound
        }

        browser.cancel()

        return discoveredEndpoint
    }

    /// Resolves a fog computing resource to an IP address.
    fileprivate static func resolveFogService(
        discoveredEndpoint: NWBrowser.Result
    ) async throws -> String {
        // Resolve the discovered endpoint to a hostname
        let connection = NWConnection(to: discoveredEndpoint.endpoint, using: .tcp)

        let resolvedService = try await withCheckedThrowingContinuation { continuation in
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    if let remoteEndpoint = connection.currentPath?.remoteEndpoint,
                       case let .hostPort(host, _) = remoteEndpoint {
                        let ipAddress: String? = switch host {
                        // No other way to get the current IP address from NWEndpoint
                        case .ipv4(let ipv4Address): ipv4Address.debugDescription.components(separatedBy: "%").first
                        case .ipv6(let ipv6Address): ipv6Address.debugDescription.components(separatedBy: "%").first
                        default: nil
                        }

                        continuation.resume(returning: ipAddress)
                    } else {
                        continuation.resume(returning: nil)
                    }

                    connection.stateUpdateHandler = nil // Prevent further updates
                    connection.cancel()
                case .cancelled, .failed:
                    connection.cancel()
                    Self.logger.error("SpeziLLMFog: \(discoveredEndpoint.endpoint.debugDescription) mDNS service could not be resolved because of a network error.")
                    continuation.resume(throwing: LLMFogError.mDnsServiceDiscoveryNetworkError())
                    return
                default:
                    break
                }
            }

            connection.start(queue: .global(qos: .userInitiated))
        }

        guard let resolvedService else {
            Self.logger.error("SpeziLLMFog: \(discoveredEndpoint.endpoint.debugDescription) mDNS service could not be resolved to an IP.")
            throw LLMFogError.mDnsServicesNotFound
        }

        Self.logger.debug("SpeziLLMFog: \(discoveredEndpoint.endpoint.debugDescription) mDNS service resolved to: \(resolvedService).")

        return resolvedService
    }
}
