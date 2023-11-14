//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import os

/// Delegate of the ``LLMLocalDownloadManager`` that conforms to the `URLSessionDownloadDelegate`.
class LLMLocalDownloadManagerDelegate: NSObject, URLSessionDownloadDelegate {
    /// A Swift Logger that logs important information from the `LocalLLMDownloadManager`.
    private static let logger = Logger(subsystem: "edu.stanford.spezi", category: "SpeziML")
    /// A `weak` reference to the ``LLMLocalDownloadManager``.
    private weak var manager: LLMLocalDownloadManager?
    /// The storage location `URL` of the downloaded LLM.
    private let storageUrl: URL

    
    /// Creates a new `LLMLocalDownloadManagerDelegate`
    /// - Parameters:
    ///   - manager: The ``LLMLocalDownloadManager`` from which the `LLMLocalDownloadManagerDelegate` is initialized.
    ///   - storageUrl: The `URL` where the downloaded LLM should be stored.
    init(manager: LLMLocalDownloadManager, storageUrl: URL) {
        self.manager = manager
        self.storageUrl = storageUrl
    }

    
    /// Indicates the progress of the current model download.
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) * 100
        Task { @MainActor in
            self.manager?.state = .downloading(progress: progress)
        }
    }

    /// Indicates the completion of the model download including the downloaded file `URL`.
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            _ = try FileManager.default.replaceItemAt(self.storageUrl, withItemAt: location)
            Task { @MainActor in
                self.manager?.state = .downloaded
            }
        } catch {
            Task { @MainActor in
                self.manager?.state = .error(error)
            }
            Self.logger.error("\(String(describing: error))")
        }
    }

    /// Indicates an error during the model download
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            Task { @MainActor in
                self.manager?.state = .error(error)
            }
            Self.logger.error("\(String(describing: error))")
        }
    }
}
