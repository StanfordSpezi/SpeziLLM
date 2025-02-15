//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Network
import OpenAPIRuntime
import OpenAPIURLSession


extension LLMFogSession {
    /// Set up the Fog LLM execution client.
    ///
    /// - Parameters:
    ///   - continuation: A Swift `AsyncThrowingStream` that streams the generated output.
    /// - Returns: `true` if the setup was successful, `false` otherwise.
    func _setup(continuation: AsyncThrowingStream<String, Error>.Continuation) async -> Bool {
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
            await finishGenerationWithError(LLMFogError.unknownError(error), on: continuation)
            return false
        }
        
//        self.wrappedModel = OpenAI(
//            configuration: .init(
//                token: await schema.parameters.authToken(),
//                host: fogServiceAddress,
//                port: (caCertificate != nil) ? 443 : 80,
//                scheme: (caCertificate != nil) ? "https" : "http",
//                timeoutInterval: platform.configuration.timeout,
//                caCertificate: caCertificate,
//                expectedHost: platform.configuration.host
//            )
//        )

        // Initialize the OpenAI model
        do {
            let urlString = """
            \((caCertificate != nil) ? "https" : "http")://\(fogServiceAddress):\((caCertificate != nil) ? 443 : 80)
            """
            guard let url = URL(string: urlString) else {
                preconditionFailure("couldn;t create URL")  // todo
            }
            guard let authToken = await schema.parameters.authToken() else {
                preconditionFailure("couldn;t get auth token")  // todo
            }


            // TODO: Map this properly to OpenAPI client with the ca cert and expected host and timeout (also, must url include a /v1?)
            wrappedClient = Client(
                serverURL: url,
                transport: URLSessionTransport(),
                middlewares: [AuthMiddleware(APIKey: authToken)]
            )
        } catch {   // todo: we dont need this catch anymore?
            Self.logger.error("""
            SpeziLLMFog: Couldn't create Fog client with the token present in the Spezi secure storage.
            \(error.localizedDescription)
            """)
            return false
        }

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
