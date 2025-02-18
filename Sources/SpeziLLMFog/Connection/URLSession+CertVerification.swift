//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import os
import Security


final class TransportCertificateValidationDelegate: NSObject, URLSessionDelegate {
    private let caCertificate: SecCertificate?
    private let expectedHost: String?
    private let logger: Logger


    /// Create an instance of the `TransportCertificateValidation`
    ///
    /// - Parameters:
    ///    - caCertificate: The optional, to-be-trusted custom CA certificate.
    ///    - expectedHost: The optional expected hostname to verify the received TLS token against. Useful for network requests to another domain or IP than the host issued the TLS token (e.g. within a local network with non-public hostnames and requests via IPs)
    ///    - logger: The logger used by SpeziLLM.
    init(caCertificate: SecCertificate?, expectedHost: String?, logger: Logger) {
        self.caCertificate = caCertificate
        self.expectedHost = expectedHost
        self.logger = logger
    }


    /// Handle custom TLS certificate verification.
    ///
    /// Uses the `caCertificate` and `expectedHost` parameters of the `StreamingSession` to verify the server's authenticity and establish a secure SSL connection.
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust,
              let caCertificate, let expectedHost else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        // Set the anchor certificate
        let anchorCertificates: [SecCertificate] = [caCertificate]
        SecTrustSetAnchorCertificates(serverTrust, anchorCertificates as CFArray)

        SecTrustSetAnchorCertificatesOnly(serverTrust, true)

        let policy = SecPolicyCreateSSL(true, expectedHost as CFString)
        SecTrustSetPolicies(serverTrust, policy)

        var error: CFError?
        if SecTrustEvaluateWithError(serverTrust, &error) {
            // Trust evaluation succeeded, proceed with the connection
            logger.debug("SpeziLLMOpenAI: Trust evaluation succeeded, proceed the connection.")
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            // Trust evaluation failed, handle the error
            logger.warning("SpeziLLMOpenAI: Trust evaluation failed with error: \(error?.localizedDescription ?? "unknown")")
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
