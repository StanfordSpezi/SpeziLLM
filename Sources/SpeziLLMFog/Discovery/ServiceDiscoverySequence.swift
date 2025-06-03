//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Network


/// An `AsyncSequence` of discovered services within the local network for a certain host and service type.
struct ServiceDiscoverySequence: AsyncSequence, Sendable {
    typealias Element = Set<NWBrowser.Result>
    typealias AsyncIterator = AsyncThrowingStream<Element, any Error>.Iterator


    let serviceType: String
    let host: String
    let includePeerToPeer: Bool
    let queue: DispatchQueue


    /// Initialize a new `AsyncSequence` yielding discovered services within the local network.
    ///
    /// - Parameters:
    ///   - serviceType: The service type of the to be discovered service, such as `_https._tcp`.
    ///   - host: The host of the to be discovered service.
    ///   - includePeerToPeer: Allow the inclusion of peer-to-peer interfaces when listening or establishing outbound connections, defaults to `false`.
    ///   - queue: The dispatch queue on which browser callbacks will be delivered, defaults to `.global(qos: .userInitiated)`.
    init(
        serviceType: String,
        host: String,
        includePeerToPeer: Bool = false,
        queue: DispatchQueue = .global(qos: .userInitiated)
    ) {
        self.serviceType = serviceType
        self.host = host
        self.includePeerToPeer = includePeerToPeer
        self.queue = queue
    }


    func makeAsyncIterator() -> AsyncIterator {
        let browser = NWBrowser(
            for: .bonjour(
                type: self.serviceType,
                domain: self.host + "."
            ),
            using: .tcp
        )

        browser.parameters.includePeerToPeer = self.includePeerToPeer

        let stream = AsyncThrowingStream<Element, any Error> { continuation in
            browser.browseResultsChangedHandler = { newResults, _ in        // we always yield all new results (a `Set`) and return them
                continuation.yield(newResults)
            }

            browser.stateUpdateHandler = { state in
                switch state {
                case .failed(let error):
                    LLMFogPlatform.logger.error("SpeziLLMFog: MDNS service discovery failed with error \(error.debugDescription)")
                    continuation.finish(throwing: LLMFogError.mDnsServiceDiscoveryNetworkError(cause: error))
                case .cancelled:
                    continuation.finish()
                default:
                    break
                }
            }

            browser.start(queue: self.queue)

            continuation.onTermination = { _ in
                browser.cancel()
            }
        }

        return stream.makeAsyncIterator()
    }
}
