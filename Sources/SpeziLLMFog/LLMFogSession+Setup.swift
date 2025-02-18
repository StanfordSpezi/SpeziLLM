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


extension LLMFogSession {
    /// Set up the Fog LLM execution client.
    ///
    /// - Parameters:
    ///   - continuation: A Swift `AsyncThrowingStream` that streams the generated output.
    /// - Returns: `true` if the setup was successful, `false` otherwise.
    func _setup(continuation: AsyncThrowingStream<String, any Error>.Continuation) async -> Bool {
        // swiftlint:disable:previous function_body_length identifier_name
        Self.logger.debug("SpeziLLMFog: Fog LLM is being initialized")
        await MainActor.run {
            self.state = .loading
        }
        
        var caCertificate: SecCertificate?
        
        if let caCertificateUrl = platform.configuration.caCertificate {
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
                await finishGenerationWithError(LLMFogError.missingCaCertificate, on: continuation)
                return false
            }
            
            caCertificate = caCreatedCertificate
        }
        
        let fogServiceAddress: String
        
        do {
            // Discover and resolve fog service
            fogServiceAddress = try await resolveFogService(secureTraffic: caCertificate != nil)
            self.discoveredServiceAddress = fogServiceAddress
        } catch is CancellationError {
            Self.logger.debug("SpeziLLMFog: mDNS task discovery has been aborted because of Task cancellation.")
            continuation.finish()
            return false
        } catch let error as LLMFogError {
            await finishGenerationWithError(error, on: continuation)
            return false
        } catch {
            await finishGenerationWithError(LLMFogError.unknownError(error.localizedDescription), on: continuation)
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
            await finishGenerationWithError(LLMFogError.mDnsServiceDiscoveryNetworkError, on: continuation)
            return false
        }

        wrappedClient = Client(
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
                AuthMiddleware(
                    authToken: schema.parameters.authToken,
                    expectedHost: platform.configuration.host
                )
            ]
        )

        await MainActor.run {
            self.state = .ready
        }
        Self.logger.debug("SpeziLLMFog: Fog LLM finished initializing, now ready to use")
        return true
    }
    
    /// Resolves a Spezi Fog LLM computing resource to an IP address.
    private func resolveFogService(secureTraffic: Bool = true) async throws -> String {
        // Browse for configured mDNS services
        let browser = NWBrowser(
            for: .bonjour(
                type: secureTraffic ? "_https._tcp" : "_http._tcp",
                domain: platform.configuration.host + "."
            ),
            using: .init()
        )
        
        browser.start(queue: .global(qos: .userInitiated))
        
        // Possible `Cancellation` error handled in the caller
        try await Task.sleep(for: platform.configuration.mDnsBrowsingTimeout)
        
        guard let discoveredEndpoint = browser.browseResults.randomElement()?.endpoint else {
            browser.cancel()
            Self.logger.error("SpeziLLMFog: A \(self.platform.configuration.host + ".") mDNS service of type '_https._tcp' could not be found.")
            throw LLMFogError.mDnsServicesNotFound
        }
        
        browser.cancel()
        
        // Resolve the discovered endpoint to a hostname
        let connection = NWConnection(to: discoveredEndpoint, using: .tcp)
        
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
                    Self.logger.error("SpeziLLMFog: \(discoveredEndpoint.debugDescription) mDNS service could not be resolved because of a network error.")
                    continuation.resume(throwing: LLMFogError.mDnsServiceDiscoveryNetworkError)
                    return
                default:
                    break
                }
            }
            
            connection.start(queue: .global(qos: .userInitiated))
        }
        
        guard let resolvedService else {
            Self.logger.error("SpeziLLMFog: \(discoveredEndpoint.debugDescription) mDNS service could not be resolved to an IP.")
            throw LLMFogError.mDnsServicesNotFound
        }
        
        Self.logger.debug("SpeziLLMFog: \(discoveredEndpoint.debugDescription) mDNS service resolved to: \(resolvedService).")
        
        return resolvedService
    }
}
