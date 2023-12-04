//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import os
import SpeziViews


/// Delegate of the ``LLMLocalDownloadManager`` implementing the methods of the`URLSessionDownloadDelegate` conformance.
class LLMLocalDownloadManagerDelegate: NSObject, URLSessionDownloadDelegate {
    /// A Swift `Logger` that logs important information from the `LocalLLMDownloadManager`.
    private static let logger = Logger(subsystem: "edu.stanford.spezi", category: "SpeziLLM")
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
                self.manager?.state = .downloaded(storageUrl: self.storageUrl)
            }
        } catch {
            Task { @MainActor in
                self.manager?.state = .error(
                    AnyLocalizedError(
                        error: error,
                        defaultErrorDescription:
                            LocalizedStringResource("LLM_DOWNLOAD_FAILED_ERROR", bundle: .atURL(from: .module))
                    )
                )
            }
            Self.logger.error("\(String(describing: error))")
        }
    }

    /// Indicates an error during the model download
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // The `error` property is set for client-side errors (e.g. couldn't resolve host name),
        // the `task.error` property is set in the case of server-side errors.
        // If none of these properties are set, no error has occurred.
        if let error = error ?? task.error {
            Task { @MainActor in
                self.manager?.state = .error(
                    AnyLocalizedError(
                        error: error,
                        defaultErrorDescription: LocalizedStringResource("LLM_DOWNLOAD_FAILED_ERROR", bundle: .atURL(from: .module))
                    )
                )
            }
            Self.logger.error("\(String(describing: error))")
        }
    }
}
