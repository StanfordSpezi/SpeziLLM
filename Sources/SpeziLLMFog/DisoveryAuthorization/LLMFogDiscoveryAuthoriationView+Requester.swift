//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Atomics
import Foundation
import Network
import OSLog

extension LLMFogDiscoveryAuthorizationView {
    /// Checks whether Local Network permission has been granted.
    /// If the authorization state is undetermined, it will request the user for permission.
    ///
    /// Based on: https://gist.github.com/mac-cain13/fa684f54a7ae1bba8669e78d28611784
    ///
    /// - Throws: A network error or `CancellationError` if cancelled.
    /// - Returns: `true` if local network permission is granted, `false` if denied.
    func requestLocalNetworkAuthorization() async throws -> Bool {      // swiftlint:disable:this function_body_length cyclomatic_complexity
        let logger = Logger(subsystem: "edu.stanford.spezi", category: "SpeziLLMFog")
        // If CA cert is set, browse for https discovery, otherwise http
        let type = (self.fogPlatform.configuration.caCertificate != nil) ? "_https._tcp" : "_http._tcp"

        let listener = try NWListener(using: NWParameters(tls: .none, tcp: NWProtocolTCP.Options()))
        listener.service = NWListener.Service(name: UUID().uuidString, type: type)
        listener.newConnectionHandler = { _ in }

        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        let browser = NWBrowser(for: .bonjour(type: type, domain: nil), using: parameters)

        return try await withTaskCancellationHandler {      // swiftlint:disable:this closure_body_length
            try await withCheckedThrowingContinuation { continuation in     // swiftlint:disable:this closure_body_length
                let didResume = ManagedAtomic<Bool>(false)

                @Sendable
                func resume(with result: Result<Bool, any Error>) {
                    if !didResume.compareExchange(expected: false, desired: true, ordering: .relaxed).exchanged {
                        logger.warning("Already resumed, ignoring subsequent result.")
                        return
                    }

                    // Teardown network resources
                    listener.stateUpdateHandler = nil
                    browser.stateUpdateHandler = nil
                    browser.browseResultsChangedHandler = nil
                    listener.cancel()
                    browser.cancel()

                    continuation.resume(with: result)
                }

                // Cancel immediately if task is already cancelled
                if Task.isCancelled {
                    logger.notice("Task cancelled before listener/browser setup.")
                    resume(with: .failure(CancellationError()))
                    return
                }

                listener.stateUpdateHandler = { newState in
                    switch newState {
                    case .cancelled:
                        resume(with: .failure(CancellationError()))
                    case .failed(let error):
                        logger.error("Listener failed: \(error, privacy: .public)")
                        resume(with: .failure(error))
                    case .waiting(let error):
                        logger.warning("Listener waiting: \(error, privacy: .public)")
                        resume(with: .failure(error))
                    default:
                        break       // do not care about these states
                    }
                }

                browser.stateUpdateHandler = { newState in
                    switch newState {
                    case .cancelled:
                        resume(with: .failure(CancellationError()))
                    case .failed(let error):
                        logger.error("Browser failed: \(error, privacy: .public)")
                        resume(with: .failure(error))
                    case let .waiting(error):
                        if case .dns(DNSServiceErrorType(kDNSServiceErr_PolicyDenied)) = error {
                            logger.notice("Browser denied access (PolicyDenied).")
                            resume(with: .success(false))
                        } else {
                            logger.error("Browser waiting with error: \(error, privacy: .public)")
                            resume(with: .failure(error))
                        }
                    default:
                        break       // do not care about these states
                    }
                }

                browser.browseResultsChangedHandler = { results, _ in
                    guard !results.isEmpty else {
                        logger.info("Empty browse result set; ignoring.")
                        return
                    }

                    logger.info("Discovered \(results.count) services.")
                    resume(with: .success(true))
                }

                listener.start(queue: .global(qos: .userInitiated))
                browser.start(queue: .global(qos: .userInitiated))

                if Task.isCancelled {
                    logger.notice("Task cancelled during startup.")
                    resume(with: .failure(CancellationError()))
                }
            }
        } onCancel: {
            listener.cancel()
            browser.cancel()
        }
    }
}
