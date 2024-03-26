//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Network
import OpenAI


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
        
        // Load the specified CA certificate and strip out irrelevant data
        guard let caCertificateContents = try? String(contentsOf: platform.configuration.caCertificate, encoding: .utf8)
                .replacingOccurrences(of: "-----BEGIN CERTIFICATE-----", with: "")
                .replacingOccurrences(of: "-----END CERTIFICATE-----", with: "")
                .replacingOccurrences(of: "\n", with: ""),
              let caCertificateData = Data(base64Encoded: caCertificateContents),
              let caCertificate = SecCertificateCreateWithData(nil, caCertificateData as CFData) else {
            Self.logger.error("""
            SpeziLLMFog: The to-be-trusted CA certificate ensuring encrypted traffic to the fog LLM couldn't be read.
            Please ensure that the certificate is in the `.crt` format and available under the specified URL.
            """)
            await finishGenerationWithError(LLMFogError.missingCaCertificate, on: continuation)
            return false
        }
        
        let fogServiceAddress: String
        
        do {
            // Discover and resolve fog service
            fogServiceAddress = try await resolveFogService()
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
        
        // Overwrite user id token if passed
        if let overwritingToken = schema.parameters.overwritingToken {
            self.wrappedModel = OpenAI(
                configuration: .init(
                    token: overwritingToken,
                    host: fogServiceAddress,
                    timeoutInterval: platform.configuration.timeout,
                    caCertificate: caCertificate,
                    expectedHost: platform.configuration.host
                )
            )
        } else {
            // Use firebase user id token otherwise
            guard let userToken else {
                Self.logger.error("""
                SpeziLLMFog: Missing user token.
                Please ensure that the user is logged in via SpeziAccount and the Firebase identity provider before dispatching the first inference.
                """)
                await finishGenerationWithError(LLMFogError.userNotAuthenticated, on: continuation)
                return false
            }
            
            self.wrappedModel = OpenAI(
                configuration: .init(
                    token: userToken,
                    host: fogServiceAddress,
                    timeoutInterval: platform.configuration.timeout,
                    caCertificate: caCertificate,
                    expectedHost: platform.configuration.host
                )
            )
        }
        
        await MainActor.run {
            self.state = .ready
        }
        Self.logger.debug("SpeziLLMFog: Fog LLM finished initializing, now ready to use")
        return true
    }
    
    /// Resolves a Spezi Fog LLM computing resource to an IP address.
    private func resolveFogService() async throws -> String {
        // Browse for configured mDNS services
        let browser = NWBrowser(
            for: .bonjour(type: "_https._tcp", domain: platform.configuration.host + "."),
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
